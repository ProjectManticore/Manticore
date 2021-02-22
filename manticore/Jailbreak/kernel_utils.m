//
//  kernel_u.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include "../Misc/support.h"
#include "../Exploit/cicuta_virosa.h"
#include <mach/mach_traps.h>
#include <mach/mach.h>
#include "kernel_utils.h"
#include "patchfinder64.h"
#include "../Misc/kernel_offsets.h"

#if 1
#define MAX_CHUNK 0xff0
#else
#define MAX_CHUNK 0x2000
#endif

mach_port_t tfp0 = MACH_PORT_NULL;
uint64_t kreads = 0;
uint64_t kwrites = 0;

kptr_t get_proc_struct_for_pid(pid_t pid){
    __block kptr_t proc = KPTR_NULL;
    void (^handler)(kptr_t, pid_t, bool *) = ^(kptr_t found_proc, pid_t found_pid, bool *iterate) {
        if (found_pid == pid) {
            proc = found_proc;
            *iterate = false;
        }
    };
    // TODO check if possible (allproc inclusive?)
    return proc;
}

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
    write_32((task_struct_addr + 0x3a0), (void*)task_t_flags);
    ret = true;
    return ret;
}

size_t kread(kptr_t where, void* p, size_t size){
    int rv;
    size_t offset = 0;
    while (offset < size) {
        mach_vm_size_t sz, chunk = MAX_CHUNK;
        if (chunk > size - offset) {
            chunk = size - offset;
        }
        rv = mach_vm_read_overwrite(tfp0,
            where + offset,
            chunk,
            (mach_vm_address_t)p + offset,
            &sz);
        if (rv || sz == 0) {
            break;
        }
        offset += sz;
    }
    kreads += offset;
    return offset;
}

uint64_t proc_of_pid(pid_t pid) {
    uint64_t proc = read_64(find_allproc()), pd;
    while (proc) { //iterate over all processes till we find the one we're looking for
        pd = read_32(proc + koffset(KSTRUCT_OFFSET_PROC_PID));
        if (pd == pid) return proc;
        proc = read_64(proc);
    }
    return 0;
}
