//
//  kernel_utils.h
//  reton
//
//  Created by Luca on 18.02.21.
//

#ifndef kernel_utils_h
#define kernel_utils_h

#include "util/kutils.h"

#define OFFSET(base_, object_) _##base_##__##object_##__offset_
typedef unsigned long long addr_t;

#ifdef __cplusplus
extern "C" {
#endif

extern kern_return_t mach_vm_read_overwrite (
    vm_map_t target_task,
    mach_vm_address_t address,
    mach_vm_size_t size,
    mach_vm_address_t data,
    mach_vm_size_t *outsize
);

kptr_t get_proc_struct_for_pid(pid_t pid);
bool set_platform_binary(kptr_t proc, bool set);
kptr_t find_vnode_with_fd(kptr_t proc, int fd);

size_t kread(kptr_t where, void* p, size_t size);

uint64_t proc_of_pid(pid_t pid);
kptr_t find_vnode_with_fd(kptr_t proc, int fd);

#ifdef __cplusplus
}
#endif

#endif /* kernel_utils_h */
