//
//  rootfs.m
//  manticore
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include <sys/mount.h>
#include <sys/snapshot.h>
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
    printf("rootfd:\t%d\n", rootfd);
    kptr_t rootfs_vnode = find_vnode_with_fd(g_exp.self_proc, rootfd);
    if(!KERN_POINTER_VALID(rootfs_vnode)) printf("Unable to get VNode for RootFS\n");
    printf("vnode:\t0x%llx\n", rootfs_vnode);
    kptr_t v_mount = kapi_read_kptr(rootfs_vnode + 0xd8);
    printf("vmount:\t0x%llx\t\t(0x%llx)\n", v_mount, (rootfs_vnode + 0xd8));
    if(!KERN_POINTER_VALID(v_mount)) printf("Got invalid v_mount pointer!\n");
    const char **snapshots = snapshot_list(rootfd);
    char *systemSnapshot = copySystemSnapshot();
    if(systemSnapshot == NULL) printf("Unable to copy system snapshot.\n");
    char *original_snapshot = "orig-fs";
    bool has_original_snapshot = NO;
    char *thedisk = "/dev/disk0s1s1";
    char *oldest_snapshot = NULL;
    if(snapshots == NULL){
        printf("Attempting to mount rootfs...\n");
        kptr_t dev_v_node = kapi_read64(v_mount + 0x980);
        if(!KERN_POINTER_VALID(dev_v_node)) printf("Unable to get vnode for root device!\n");
        kptr_t v_specinfo = kapi_read64(dev_v_node + 0x78);
        if(!KERN_POINTER_VALID(v_specinfo)) printf("Unable to get specinfo for root device.\n");
        kapi_write32(v_specinfo + 0x10, 0);
    } else {
        printf("APFS Snapshots: ");
        for (const char **snapshot = snapshots; *snapshot; snapshot++) {
            if (oldest_snapshot == NULL) oldest_snapshot = strdup(*snapshot);
            if (strcmp(original_snapshot, *snapshot) == 0) has_original_snapshot = YES;
            printf("%s\t\n", *snapshot);
        }
    }
    uint32_t v_flag = kapi_read32(v_mount + 0x70);
    printf("vflag:\t0x%x\t\t\t\t(0x%llx)\n", v_flag, (v_mount + 0x70));
    if ((v_flag & MNT_RDONLY) || (v_flag & MNT_NOSUID)) {
        v_flag &= ~(MNT_RDONLY | MNT_NOSUID);
        kapi_write32(v_mount + 0x70, v_flag & ~MNT_ROOTFS);
        char *opts = strdup(thedisk);
        if(mount("apfs", "/", MNT_UPDATE, (void *)&opts) != ERR_SUCCESS) printf("Unable to remount RootFS.\n");
        kapi_write32(v_mount + 0x70, v_flag);
    }
    if (!has_original_snapshot) if (oldest_snapshot != NULL) printf("Trying to rename oldest snapshot...\n");
    close(rootfd);
    printf("Running checks on rootfs...\n");
    printf("|--> Check #1:\t%s\n", check_root_rw()      ?   "success!" : "failure.");
    printf("|--> Check #2:\t%s\n", check_root_read()    ?   "success!" : "failure.");
}

bool check_root_rw(void){
    [[NSFileManager defaultManager] createFileAtPath:@"/.manticore_rw" contents:nil attributes:nil];
    if([[NSFileManager defaultManager] fileExistsAtPath:@"/.manticore_rw"]){
        [[NSFileManager defaultManager] removeItemAtPath:@"/.manticore_rw" error:nil];
        return true;
    }
    return false;
}

bool check_root_read(void){
    NSString *systemVersionPlist = @"/System/Library/CoreServices/SystemVersion.plist";
    NSDictionary *snapshotSystemVersion = [NSDictionary dictionaryWithContentsOfFile:systemVersionPlist];
    NSLog(@"%@", snapshotSystemVersion);
    return 0;
}
