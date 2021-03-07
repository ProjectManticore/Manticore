//
//  support.m
//  pwner
//
//  Created by Brandon Plank on 10/1/20.
//  Copyright © 2020 GeoSn0w. All rights reserved.
//

#include <Foundation/Foundation.h>
#include "support.h"
#include "cicuta_log.h"

//kptr_t find_vnode_with_fd(kptr_t proc, int fd) {
//    kptr_t ret = KPTR_NULL;
//    _assert(fd > 0);
//    _assert(KERN_POINTER_VALID(proc));
//    kptr_t fdp = read_64(proc + koffset(KSTRUCT_OFFSET_PROC_P_FD));
//    _assert(KERN_POINTER_VALID(fdp));
//    kptr_t ofp = ReadKernel64(fdp + koffset(KSTRUCT_OFFSET_FILEDESC_FD_OFILES));
//    _assert(KERN_POINTER_VALID(ofp));
//    kptr_t fpp = ReadKernel64(ofp + (fd * sizeof(kptr_t)));
//    _assert(KERN_POINTER_VALID(fpp));
//    kptr_t fgp = ReadKernel64(fpp + koffset(KSTRUCT_OFFSET_FILEPROC_F_FGLOB));
//    _assert(KERN_POINTER_VALID(fgp));
//    kptr_t vnode = ReadKernel64(fgp + koffset(KSTRUCT_OFFSET_FILEGLOB_FG_DATA));
//    _assert(KERN_POINTER_VALID(vnode));
//    ret = vnode;
//out:;
//    return ret;
//}
