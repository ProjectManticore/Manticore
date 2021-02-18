//
//  rootfs.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include "rootfs.h"
#include "../Exploit/cicuta_virosa.h"

int remount_rootfs(uint32_t proc) {
    int rootfd = open("/", O_RDONLY);
    kptr_t rootfs_vnode = find_vnode_with_fd(proc, rootfd);
    char *thedisk = "/dev/disk0s1s1";
    char *first_snapshot = NULL;
    return 0;
}

kptr_t find_vnode_with_fd(kptr_t proc, int fd) {
    kptr_t ret = KPTR_NULL;
    if(fd == 0) return 0;
    if(!KERN_POINTER_VALID(proc)) return 0;
    kptr_t fdp = read_64(proc + (0x00)); // KSTRUCT_OFFSET_PROC_P_FD
    if(!KERN_POINTER_VALID(fdp)) return 0;
    kptr_t ofp = read_64(fdp + (0x00)); // KSTRUCT_OFFSET_FILEDESC_FD_OFILES
    if(!KERN_POINTER_VALID(ofp)) return 0;
    kptr_t fpp = read_64(ofp + (fd * sizeof(kptr_t)));
    if(!KERN_POINTER_VALID(fpp)) return 0;
    kptr_t fgp = read_64(fpp + (0x00)); // KSTRUCT_OFFSET_FILEPROC_F_FGLOB
    if(!KERN_POINTER_VALID(fgp)) return 0;
    kptr_t vnode = read_64(fgp + (0x00));   //KSTRUCT_OFFSET_FILEGLOB_FG_DATA
    if(!KERN_POINTER_VALID(vnode)) return 0;
    ret = vnode;
    return ret;
}

bool check_root_rw(void){
    [[NSFileManager defaultManager] createFileAtPath:@"/.manticore_rw" contents:nil attributes:nil];
    if([[NSFileManager defaultManager] fileExistsAtPath:@"/.manticore_rw"]){
        [[NSFileManager defaultManager] removeItemAtPath:@"/.manticore_rw" error:nil];
        return true;
    }
    return false;
}
