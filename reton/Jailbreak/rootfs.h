//
//  rootfs.h
//  reton
//
//  Created by Luca on 18.02.21.
//

#ifndef rootfs_h
#define rootfs_h
#define KPTR_NULL ((kptr_t) 0)
#define VM_MIN_KERNEL_ADDRESS 0xffffffe000000000ULL
#define VM_MAX_KERNEL_ADDRESS 0xfffffff3ffffffffULL
#define KERN_POINTER_VALID(val) (((val) & 0xffffffff) != 0xdeadbeef && (val) >= VM_MIN_KERNEL_ADDRESS && (val) <= VM_MAX_KERNEL_ADDRESS)
typedef uint64_t kptr_t;

int remount_rootfs(uint32_t proc);
kptr_t find_vnode_with_fd(kptr_t proc, int fd);
bool check_root_rw(void);
#endif /* rootfs_h */