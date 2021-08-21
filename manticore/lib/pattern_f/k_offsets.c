#include <string.h>
#include <stdio.h>
#include <lib/tq/tq_common_p.h>
#include <lib/tq/utils.h>
#define Q_INTERNAL
#include <lib/tq/k_offsets.h>
#include "include/util/arm.h"

#ifndef _arm64e
#define _arm64e (is_pac == 0)
#endif

static void offsets_base_iOS_14_x() {
    kc_kernel_base = 0xFFFFFFF007004000;

    SIZE(ipc_entry)              = 0x18;
    OFFSET(ipc_entry, ie_object) =  0x0;

    OFFSET(ipc_port, ip_bits)       =  0x0;
    OFFSET(ipc_port, ip_references) =  0x4;
    OFFSET(ipc_port, ip_kobject)    = 0x68;

    OFFSET(ipc_space, is_table_size) = 0x14;
    OFFSET(ipc_space, is_table)      = 0x20;
    
    OFFSET(task, map) = 0x28;
    OFFSET(task, itk_space) = 0x330;
    
#if _arm64e
    OFFSET(task, bsd_info) = 0x3a0;
    OFFSET(task, t_flags) = 0x3f4;
#else
    OFFSET(task, bsd_info) = 0x390;
    OFFSET(task, t_flags) = 0x3d8;
#endif

    OFFSET(proc, le_next) = 0x00;
    OFFSET(proc, le_prev) = 0x08;
    OFFSET(proc, task) = 0x10;
    OFFSET(proc, p_pid) = 0x68;
    OFFSET(proc, p_ucred) = 0xf0;
    OFFSET(proc, p_fd) = 0xf8;
    OFFSET(proc, csflags) = 0x280;
    OFFSET(proc, gid) = 0x34;
    OFFSET(proc, rgid) = 0x3c;
    OFFSET(proc, uid) = 0x30;
    OFFSET(proc, ruid) = 0x38;
    OFFSET(proc, pid) = 0x68;
    
    OFFSET(filedesc, fd_ofiles) = 0x00;
    OFFSET(fileproc, fp_glob) = 0x10;
    OFFSET(fileglob, fg_data) = 0x38;
    OFFSET(pipe, buffer) = 0x10;
    
    OFFSET(ucred, cr_posix) = 0x18;
    OFFSET(ucred, cr_uid) = 0x18;
    OFFSET(ucred, cr_svuid) = 0x20;
    OFFSET(ucred, cr_ngroups) = 0x24;
    OFFSET(ucred, cr_groups) = 0x28;
    OFFSET(ucred, cr_svgid) = 0x6c;
    OFFSET(ucred, cr_rgid) = 0x68;
    OFFSET(ucred, cr_label) = 0x78;
    
    SIZE(posix_cred) = 0x60;

    OFFSET(OSDictionary, count)      = 0x14;
    OFFSET(OSDictionary, capacity)   = 0x18;
    OFFSET(OSDictionary, dictionary) = 0x20;

    OFFSET(OSString, string) = 0x10;

    OFFSET(IOSurfaceRootUserClient, surfaceClients) = 0x118;
    OFFSET(IOSurfaceClient, surface) = 0x40;
    OFFSET(IOSurface, values) = 0xe8;
    
    OFFSET(vnode, vmount) = 0xd8;
}

void kernel_offsets_init(void) {
    fprintf(stdout, "has_pac: %x\n", g_exp.has_PAC);
    util_info("using default iOS 14.3 Offsets");
    offsets_base_iOS_14_x();
    return;
}
