//
//  rootfs.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include "lib/tq/kapi.h"
#include "lib/tq/tq_common_p.h"
#include "lib/tq/utils.h"
#include "lib/snappy/snappy.h"
#include "exploit/cicuta/cicuta_virosa.h"
#include "rootfs.h"
#include "kernel_utils.h"

int remount_rootfs(kptr_t proc){

    return 0;
}



void start_rootfs_remount(void){
    printf("* ----- RootFS Remount ----- *\n");
    int rootfd = open("/", O_RDONLY);
    if(!(rootfd > 0)) printf("Unable to open rootfs.\n");
    printf("RootFD:\t%d\n", rootfd);
    kptr_t rootfs_vnode = find_vnode_with_fd(g_exp.self_proc, rootfd);
    if(!KERN_POINTER_VALID(rootfs_vnode)) printf("Unable to get VNode for RootFS\n");
    printf("VNode:\t0x%llx\n", rootfs_vnode);
    // TODO: Fix this offset (0xd8/KSTRUCT_OFFSET_VNODE_V_MOUNT)
    kptr_t v_mount = kapi_read64(rootfs_vnode + 0xd8);                                      // Offset unknown
    
    /*
        if(!KERN_POINTER_VALID(v_mount)) printf("Unable to get mount info for RootFS.\n");
        const char **snapshots = snapshot_list(rootfd);
        char *systemSnapshot = copySystemSnapshot();
        if(systemSnapshot == NULL) printf("Unable to copy system snapshot.\n");
        char *original_snapshot = "orig-fs";
        bool has_original_snapshot = NO;
        char *thedisk = "/dev/disk0s1s1";
        char *oldest_snapshot = NULL;
        util_runCommand("/sbin/mount");
     */
}

bool check_root_rw(void){
    [[NSFileManager defaultManager] createFileAtPath:@"/.manticore_rw" contents:nil attributes:nil];
    if([[NSFileManager defaultManager] fileExistsAtPath:@"/.manticore_rw"]){
        [[NSFileManager defaultManager] removeItemAtPath:@"/.manticore_rw" error:nil];
        return true;
    }
    return false;
}
