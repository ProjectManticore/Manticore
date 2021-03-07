//
//  rootfs.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include <sys/mount.h>
#include "lib/tq/kapi.h"
#include "lib/tq/tq_common_p.h"
#include "lib/tq/utils.h"
#include "lib/snappy/snappy.h"
#include "exploit/cicuta/cicuta_virosa.h"
#include "rootfs.h"
#include "kernel_utils.h"


void start_rootfs_remount(void){
    printf("* ----- RootFS Remount ----- *\n");
    int rootfd = open("/", O_RDONLY);
    if(!(rootfd > 0)) printf("Unable to open rootfs.\n");
    printf("RootFD:\t%d\n", rootfd);
    kptr_t rootfs_vnode = find_vnode_with_fd(g_exp.self_proc, rootfd);
    if(!KERN_POINTER_VALID(rootfs_vnode)) printf("Unable to get VNode for RootFS\n");
    printf("vnode:\t0x%llx\n", rootfs_vnode);
    kptr_t v_mount = kapi_read64(rootfs_vnode + 0xd8);
    printf("vmount:\t0x%llx\n", v_mount);
    if(!KERN_POINTER_VALID(v_mount)) printf("Got invalid v_mount pointer!\n");
    const char **snapshots = snapshot_list(rootfd);
    char *systemSnapshot = copySystemSnapshot();
    char *original_snapshot = "orig-fs";
    bool has_original_snapshot = NO;
    char *thedisk = "/dev/disk0s1s1";
    char *oldest_snapshot = NULL;
    if(systemSnapshot == NULL) printf("Unable to copy system snapshot.\n");
    if(util_runCommand("/sbin/mount", NULL) != ERR_SUCCESS) printf("Unable to print mount list.\n");
    if(snapshots == NULL){
        printf("Attempting to mount rootfs...\n");
        kptr_t dev_v_node = kapi_read64(v_mount + 0x980);
        if(!KERN_POINTER_VALID(dev_v_node)) printf("Unable to get vnode for root device!\n");
        kptr_t v_specinfo = kapi_read64(dev_v_node + 0x78);
        if(!KERN_POINTER_VALID(v_specinfo)) printf("Unable to get specinfo for root device.\n");
        kapi_write32(v_specinfo + 0x10, 0);
    } else {
        printf("APFS Snapshots:\n");
        for (const char **snapshot = snapshots; *snapshot; snapshot++) {
            if (oldest_snapshot == NULL) oldest_snapshot = strdup(*snapshot);
            if (strcmp(original_snapshot, *snapshot) == 0) has_original_snapshot = YES;
            printf("|-----> %s\n", *snapshot);
        }
    }
}

bool check_root_rw(void){
    [[NSFileManager defaultManager] createFileAtPath:@"/.manticore_rw" contents:nil attributes:nil];
    if([[NSFileManager defaultManager] fileExistsAtPath:@"/.manticore_rw"]){
        [[NSFileManager defaultManager] removeItemAtPath:@"/.manticore_rw" error:nil];
        return true;
    }
    return false;
}
