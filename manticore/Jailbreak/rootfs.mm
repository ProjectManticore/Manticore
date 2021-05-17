//
//  rootfs.m
//  manticore
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include <sys/mount.h>
#include <sys/snapshot.h>
#include <lib/snappy/snappy.h>
#include <lib/tq/utils.h>
#include <lib/tq/tq_common_p.h>
#include <lib/tq/kapi.h>
#include <stdio.h>
#include <unistd.h>
#include <exploit/cicuta/cicuta_virosa.h>
#include <manticore/rootfs.h>
#include <manticore/utils.h>
#include <manticore/kernel_utils.h>
#include <lib/tq/k_utils.h>
#include "offset_finder.h"

void restore_rootfs(void){
    printf("-> Restoring rootfs..\n");
    int rootfd = open("/", O_RDONLY);
    if(rootfd <= 0) printf("-> Unable to open rootfs!\n");
    const char **snapshots = snapshot_list(rootfd);
    if(snapshots == NULL) printf("-> Unable to get snapshot for RootFS.\n");
    if(*snapshots == NULL) printf("-> Found no snapshot for RootFS.\n");
    char *snapshot = strdup(*snapshots);
    printf("-> %s\n", snapshot);
    char *systemSnapshot = copySystemSnapshot();
    if(systemSnapshot == NULL) printf("-> Unable to copy system snapshot.\n");
    if(execute_with_kernel_credentials(^{
        if(fs_snapshot_rename(rootfd, snapshot, systemSnapshot, 0) != ERR_SUCCESS) printf("-> Unable to rename original snapshot.\n");
    })) printf("-> Successfully renamed original snapshot...\n");
    free(snapshot);
    snapshot = strdup(systemSnapshot);
    if(snapshot == NULL) printf("-> Unable to duplicate string.\n");
    free(systemSnapshot);
    char *systemSnapshotMountPoint = "/private/var/mnt/manticore/mnt2";
    if (isMountpoint(systemSnapshotMountPoint)) {
        execute_with_kernel_credentials(^{
            if(unmount(systemSnapshotMountPoint, MNT_FORCE) != ERR_SUCCESS) printf("-> Unable to unmount old snapshot mount point.\n");
        });
    }
}

void start_rootfs_remount(void){
    bool needStrap = NO;
    printf("* ----- RootFS Remount ----- *\n");
    int rootfd = open("/", O_RDONLY);
    if(!(rootfd > 0)) printf("-> Unable to open rootfs.\n");
    printf("-> rootfd:\t%d\n", rootfd);
    kptr_t rootfs_vnode = find_vnode_with_fd(g_exp.self_proc, rootfd);
    if(!KERN_POINTER_VALID(rootfs_vnode)) printf("Unable to get VNode for RootFS\n");
    printf("-> vnode:\t0x%llx\n", rootfs_vnode);
    kptr_t v_mount = kapi_read_kptr(rootfs_vnode + 0xd8);
    printf("-> vmount:\t0x%llx\t\t(0x%llx)\n", v_mount, (rootfs_vnode + 0xd8));
    if(!KERN_POINTER_VALID(v_mount)) printf("--> Got invalid v_mount pointer!\n");
    const char **snapshots = snapshot_list(rootfd);
    char *systemSnapshot = copySystemSnapshot();
    if(systemSnapshot == NULL) printf("--> Unable to copy system snapshot.\n");
    char *original_snapshot = "orig-fs";
    bool has_original_snapshot = NO;
    char *thedisk = "/dev/disk0s1s1";
    char *oldest_snapshot = NULL;
    if(snapshots == NULL){
        printf("--> Attempting to mount rootfs...\n");
        kptr_t dev_v_node = kapi_read64(v_mount + 0x980);
        if(!KERN_POINTER_VALID(dev_v_node)) printf("---> Unable to get vnode for root device!\n");
        kptr_t v_specinfo = kapi_read64(dev_v_node + 0x78);
        if(!KERN_POINTER_VALID(v_specinfo)) printf("---> Unable to get specinfo for root device.\n");
        kapi_write32(v_specinfo + 0x10, 0);
        uint32_t v_flag = kapi_read32(v_mount + 0x70);
        printf("-> vflag:\t0x%x\t\t\t\t(0x%llx)\n", v_flag, (v_mount + 0x70));
        if ((v_flag & MNT_RDONLY) || (v_flag & MNT_NOSUID)) {
            v_flag &= ~(MNT_RDONLY | MNT_NOSUID);
            kapi_write32(v_mount + 0x70, v_flag & ~MNT_ROOTFS);
            char *opts = strdup(thedisk);
            if(mount("apfs", "/", MNT_UPDATE, (void *)&opts) != ERR_SUCCESS) printf("--> Unable to remount RootFS.\n");
            kapi_write32(v_mount + 0x70, v_flag);
        }
        if (!has_original_snapshot) if (oldest_snapshot != NULL) printf("-> Trying to rename oldest snapshot...\n");
        close(rootfd);
        printf("-> Running checks on rootfs...\n");
        printf("|--> Check #1:\t%s\n", check_root_write()   ?   "success!" : "failure.");
        printf("|--> Check #2:\t%s\n", check_root_read()    ?   "success!" : "failure.");
        if(isMountpoint("/var/MobileSoftwareUpdate/mnt1")) printf("-> System already mounted(?)\n");
        char *rootFsMountPoint = "/private/var/mnt/manticore/mnt1";
        if(isMountpoint(rootFsMountPoint)){
            printf("-> Unmounting old rootfs mount point...\n");
            if(unmount(rootFsMountPoint, MNT_FORCE) != ERR_SUCCESS){
                printf("-> Unable to unmount old rootfs mount point\n");
            }
        }
        if(deleteFile(rootFsMountPoint) != true) printf("-> Unable to clean old rootfs mount point\n");
        if(ensureDirectory(rootFsMountPoint, getuid(), 0755) != true){
            printf("-> Unable to create mount point. (Missing parent directory)\n");
        }
        const char *argv[] = {"/sbin/mount_apfs", thedisk, rootFsMountPoint, NULL};
        if(runCommandv(argv[0], 3, argv, ^(pid_t pid) {
            kptr_t procStructAddr = kproc_find_by_pid(pid);
            if(KERN_POINTER_INVALID(procStructAddr)) printf("Unable to find mount_apfs's process in kernel memory. (%s/%d)\n", get_path_for_pid(pid), pid);
            give_creds_to_proc_at_addr(procStructAddr, get_kernel_cred_addr(g_exp.kernel_proc));
        }, true, false) != ERR_SUCCESS) printf("-> Unable to mount RootFS.\n");
        if(util_runCommand("/sbin/mount", NULL) != ERR_SUCCESS) printf("-> Unable to print new mount list.\n");
        const char *systemSnapshotLaunchdPath = [@(rootFsMountPoint) stringByAppendingPathComponent:@"sbin/launchd"].UTF8String;
        if(waitForFile(systemSnapshotLaunchdPath) != ERR_SUCCESS) printf("-> Unable to verify newly mounted RootFS.\n");
        printf("-> Successfully mounted RootFS.\n");
        printf("-> Renaming system snapshot...\n");
        close(rootfd);
        rootfd = open(rootFsMountPoint, O_RDONLY);
        if(rootfd <= 0) printf("Unable to open newly mounted RootFS.\n");
        rootfs_vnode = find_vnode_with_fd(g_exp.self_proc, rootfd);
        if(!KERN_POINTER_VALID(rootfs_vnode)) printf("-> Unable to get vnode for newly mounted RootFS.\n");
        v_mount = kapi_read_kptr(rootfs_vnode + 0xd8);
        if(!KERN_POINTER_VALID(v_mount)) printf("-> Unable to get mount info for newly mounted RootFS.\n");
        snapshots = snapshot_list(rootfd);
        if(snapshots == NULL) printf("-> Unable to get snapshots for newly mounted RootFS.\n");
        printf("--> Snapshots on newly mounted RootFS: \n");
        for (const char **snapshot = snapshots; *snapshot; snapshot++) {
            printf("-> \t%s\n", *snapshot);
            if (strcmp(*snapshot, original_snapshot) == 0) {
                printf("-> Clearing old original system snapshot...\n");
                if(!execute_with_kernel_credentials(^{
                    fs_snapshot_delete(rootfd, original_snapshot, 0);
                })) printf("--> Unable to clear old original system snapshot.\n");
            }
        }
        
        free(snapshots);
    }else {
        printf("-> APFS Snapshots: ");
        for (const char **snapshot = snapshots; *snapshot; snapshot++) {
            if (oldest_snapshot == NULL) oldest_snapshot = strdup(*snapshot);
            if (strcmp(original_snapshot, *snapshot) == 0) has_original_snapshot = YES;
            printf("%s\t\n", *snapshot);
        }
    }
    
    uint32_t v_flag = kapi_read32(v_mount + 0x70);
    if ((v_flag & MNT_RDONLY) || (v_flag & MNT_NOSUID)) {
        v_flag &= ~(MNT_RDONLY | MNT_NOSUID);
        kapi_write32(v_mount + 0x70, v_flag & ~MNT_ROOTFS);
        char *opts = strdup(thedisk);
        if(mount("apfs", "/", MNT_UPDATE, (void *)&opts) != ERR_SUCCESS) printf("-> Unable to remount RootFS.\n");
        free(opts);
        kapi_write32(v_mount + 0x70, v_flag);
    }
    if(util_runCommand("/sbin/mount", NULL) != ERR_SUCCESS) printf("-> Unable to print new mount list.\n");
    NSString *file = [NSString stringWithContentsOfFile:@"/.manticore" encoding:NSUTF8StringEncoding error:nil];
    needStrap = file == nil;
    needStrap |= ![file isEqualToString:@""] && ![file isEqualToString:[NSString stringWithFormat:@"%f\n", kCFCoreFoundationVersionNumber]];
    needStrap &= access("/taurine", F_OK) != ERR_SUCCESS;
    needStrap &= access("/unc0ver", F_OK) != ERR_SUCCESS;
    if (needStrap)
        printf("-> We need strap.\n");
    if (!has_original_snapshot) {
        if (oldest_snapshot != NULL) {
            if(execute_with_kernel_credentials(^{
                if(fs_snapshot_rename(rootfd, oldest_snapshot, original_snapshot, 0) != ERR_SUCCESS) printf("-> Unable to rename oldest snapshot!\n");
            })) printf("-> Successfully renamed oldest snapshot\n");
        } else if (needStrap) {
            if(execute_with_kernel_credentials(^{
                if(fs_snapshot_create(rootfd, original_snapshot, 0) != ERR_SUCCESS) printf("-> Unable to create stock snapshot!\n");
            })) printf("-> Successfully created stock snapshot\n");
        }
    }
    close(rootfd);
    free(snapshots);
    free(systemSnapshot);
    free(oldest_snapshot);
    printf("-> Successfully remounted RootFS.\n");
}

bool check_root_write(void){
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
    if(snapshotSystemVersion[@"ProductVersion"]) return true;
    if([snapshotSystemVersion count] > 0) return true;
    return false;
}
