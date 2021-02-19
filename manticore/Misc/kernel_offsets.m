//
//  kernel_offsets.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include "kernel_offsets.h"

// Offset templates taken from iOS 13

kernel_offset_array dynamic_koffsets_ios_14_4(void){
    kernel_offset_array offset_arr;
    /* struct proc */
        offset_arr.KSTRUCT_OFFSET_PROC_PID = 0x68;          // KSTRUCT_OFFSET_PROC_PID
        offset_arr.KSTRUCT_OFFSET_PROC_TASK = 0x10;         // KSTRUCT_OFFSET_PROC_TASK
        offset_arr.KSTRUCT_OFFSET_PROC_UCRED = 0xF0;        // KSTRUCT_OFFSET_PROC_UCRED
        offset_arr.KSTRUCT_OFFSET_PROC_CSFLAGS = 0x280;     // KSTRUCT_OFFSET_PROC_CSFLAGS
        offset_arr.KSTRUCT_OFFSET_PROC_RGID = 0x3C;         // KSTRUCT_OFFSET_PROC_RGID
        offset_arr.KSTRUCT_OFFSET_PROC_RUID = 0x38;         // KSTRUCT_OFFSET_PROC_RUID
        offset_arr.KSTRUCT_OFFSET_PROC_GID = 0x34;          // KSTRUCT_OFFSET_PROC_GID
        offset_arr.KSTRUCT_OFFSET_PROC_UID = 0x30;          // KSTRUCT_OFFSET_PROC_UID
    /* struct ucred */
        offset_arr.KSTRUCT_OFFSET_UCRED_CR_UID = 0x18;      // KSTRUCT_OFFSET_UCRED_CR_UID
        offset_arr.KSTRUCT_OFFSET_UCRED_CR_RUID = 0x1C;     // KSTRUCT_OFFSET_UCRED_CR_RUID
        offset_arr.KSTRUCT_OFFSET_UCRED_CR_SVUID = 0x20;    // KSTRUCT_OFFSET_UCRED_CR_SVUID
        offset_arr.KSTRUCT_OFFSET_UCRED_CR_NGROUPS = 0x24;  // KSTRUCT_OFFSET_UCRED_CR_NGROUPS
        offset_arr.KSTRUCT_OFFSET_UCRED_CR_GROUPS = 0x28;   // KSTRUCT_OFFSET_UCRED_CR_GROUPS
        offset_arr.KSTRUCT_OFFSET_UCRED_CR_RGID = 0x68;     // KSTRUCT_OFFSET_UCRED_CR_RGID
        offset_arr.KSTRUCT_OFFSET_UCRED_CR_SVGID = 0x6C;    // KSTRUCT_OFFSET_UCRED_CR_SVGID
        offset_arr.KSTRUCT_OFFSET_UCRED_CR_LABEL = 0x78;    // KSTRUCT_OFFSET_UCRED_CR_LABEL
    /* struct task */
        offset_arr.KSTRUCT_OFFSET_TASK_TFLAGS = 0x280;
    /* sandbox */
        offset_arr.KSTRUCT_OFFSET_SANDBOX_SLOT = 0x10;
    return offset_arr;
}

uint32_t kernel_offsets_14_3[] = {
    /* struct proc */
        0x68,   // KSTRUCT_OFFSET_PROC_PID
        0x10,   // KSTRUCT_OFFSET_PROC_TASK
        0xF0,   // KSTRUCT_OFFSET_PROC_UCRED
        0x280,  // KSTRUCT_OFFSET_PROC_CSFLAGS
        0x3C,   // KSTRUCT_OFFSET_PROC_RGID
        0x38,   // KSTRUCT_OFFSET_PROC_RUID
        0x34,   // KSTRUCT_OFFSET_PROC_GID
        0x30,   // KSTRUCT_OFFSET_PROC_UID
    
    /* struct ucred */
        0x18,   // KSTRUCT_OFFSET_UCRED_CR_UID
        0x1C,   // KSTRUCT_OFFSET_UCRED_CR_RUID
        0x20,   // KSTRUCT_OFFSET_UCRED_CR_SVUID
        0x24,   // KSTRUCT_OFFSET_UCRED_CR_NGROUPS
        0x28,   // KSTRUCT_OFFSET_UCRED_CR_GROUPS
        0x68,   // KSTRUCT_OFFSET_UCRED_CR_RGID
        0x6C,   // KSTRUCT_OFFSET_UCRED_CR_SVGID
        0x78,   // KSTRUCT_OFFSET_UCRED_CR_LABEL
    
    /* struct task */
        0x3A0,  // KSTRUCT_OFFSET_TASK_TFLAGS
    
    
//    0x00, // 0xb, /* KSTRUCT_OFFSET_TASK_LCK_MTX_TYPE */
//    0x00, // 0x10, /* KSTRUCT_OFFSET_TASK_REF_COUNT */
//    0x00, // 0x14, /* KSTRUCT_OFFSET_TASK_ACTIVE */
//    0x00, // 0x00, // 0x28, /* KSTRUCT_OFFSET_TASK_VM_MAP */
//    0x00, // 0x00, // 0x30, /* KSTRUCT_OFFSET_TASK_NEXT */
//    0x00, // 0x00, // 0x38, /* KSTRUCT_OFFSET_TASK_PREV */
//    0x00, // 0x00, // 0x320, /* KSTRUCT_OFFSET_TASK_ITK_SPACE */
//    0x00, // 0x380, /* KSTRUCT_OFFSET_TASK_BSD_INFO */
//    0x00, // 0x3d0 - 0x8, /* KSTRUCT_OFFSET_TASK_ALL_IMAGE_INFO_ADDR */
//    0x00, // 0x3d8 - 0x8, /* KSTRUCT_OFFSET_TASK_ALL_IMAGE_INFO_SIZE */
//    0x00, // 0x3d8 - 0x8, /* KSTRUCT_OFFSET_TASK_TFLAGS */
//    0x00, // 0x0, /* KSTRUCT_OFFSET_TASK_LOCK */
//    0x00, // 0x0, /* KSTRUCT_OFFSET_IPC_PORT_IO_BITS */
//    0x00, // 0x4, /* KSTRUCT_OFFSET_IPC_PORT_IO_REFERENCES */
//    0x00, // 0x40, /* KSTRUCT_OFFSET_IPC_PORT_IKMQ_BASE */
//    0x00, // 0x50, /* KSTRUCT_OFFSET_IPC_PORT_MSG_COUNT */
//    0x00, // 0x60, /* KSTRUCT_OFFSET_IPC_PORT_IP_RECEIVER */
//    0x00, // 0x68, /* KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT */
//    0x00, // 0x88, /* KSTRUCT_OFFSET_IPC_PORT_IP_PREMSG */
//    0x00, // 0x90, /* KSTRUCT_OFFSET_IPC_PORT_IP_CONTEXT */
//    0x00, // 0xa0, /* KSTRUCT_OFFSET_IPC_PORT_IP_SRIGHTS */
//    0x00, // 0x68, /* KSTRUCT_OFFSET_PROC_PID */
//    0x00, // 0x108, /* KSTRUCT_OFFSET_PROC_P_FD */
//    0x00, // 0x10, /* KSTRUCT_OFFSET_PROC_TASK */
//    0x00, // 0x100, /* KSTRUCT_OFFSET_PROC_UCRED */
//    0x00, // 0x0, /* KSTRUCT_OFFSET_PROC_P_LIST */
//    0x00, // 0x298, /* KSTRUCT_OFFSET_PROC_P_CSFLAGS */
//    0x00, // 0x3f8, /* KSTRUCT_OFFSET_PROC_P_MEMSTAT_STATE */
//    0x00, // 0x50, /* KSTRUCT_OFFSET_PROC_MLOCK */
//    0x00, // 0xe8, /* KSTRUCT_OFFSET_PROC_UCRED_MLOCK */
//    0x00, // 0x32, /* KSTRUCT_OFFSET_PROC_SVUID */
//    0x00, // 0x36, /* KSTRUCT_OFFSET_PROC_SVGID */
//    0x00, // 0x144, /* KSTRUCT_OFFSET_PROC_P_FLAG */
//    0x00, // 0x238, /* KSTRUCT_OFFSET_PROC_TEXTVP */
//    0x00, // 0x0, /* KSTRUCT_OFFSET_FILEDESC_FD_OFILES */
//    0x00, // 0x10, /* KSTRUCT_OFFSET_FILEPROC_F_FGLOB */
//    0x00, // 0x38, /* KSTRUCT_OFFSET_FILEGLOB_FG_DATA */
//    0x00, // 0x28, /* KSTRUCT_OFFSET_FILEGLOB_FG_OPS */
//    0x00, // 0x10, /* KSTRUCT_OFFSET_SOCKET_SO_PCB */
//    0x00, // 0x10, /* KSTRUCT_OFFSET_PIPE_BUFFER */
//    0x00, // 0x14, /* KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE_SIZE */
//    0x00, // 0x20, /* KSTRUCT_OFFSET_IPC_SPACE_IS_TABLE */
//    0x00, // 0xd8, /* KSTRUCT_OFFSET_VNODE_V_MOUNT */
//    0x00, // 0x78, /* KSTRUCT_OFFSET_VNODE_VU_SPECINFO */
//    0x00, // 0x0, /* KSTRUCT_OFFSET_VNODE_V_LOCK */
//    0x00, // 0xe0, /* KSTRUCT_OFFSET_VNODE_V_DATA */
//    0x00, // 0x78, /* KSTRUCT_OFFSET_VNODE_V_UBCINFO */
//    0x00, // 0x30, /* KSTRUCT_OFFSET_VNODE_V_NCCHILDREN_TQH_FIRST */
//    0x00, // 0x20, /* KSTRUCT_OFFSET_VNODE_V_MNTVNODES_TQE_NEXT */
//    0x00, // 0x10, /* KSTRUCT_OFFSET_SPECINFO_SI_FLAGS */
//    0x00, // 0x70, /* KSTRUCT_OFFSET_MOUNT_MNT_FLAG */
//    0x00, // 0x8f8, /* KSTRUCT_OFFSET_MOUNT_MNT_DATA */
//    0x00, // 0x18, /* KSTRUCT_OFFSET_MOUNT_MNT_MLOCK */
//    0x00, // 0x980, /* KSTRUCT_OFFSET_MOUNT_MNT_DEVVP */
//    0x00, // 0x40, /* KSTRUCT_OFFSET_MOUNT_MNT_VNODELIST_TQH_FIRST */
//    0x00, // 0x10, /* KSTRUCT_OFFSET_HOST_SPECIAL */
//    0x00, // 0x10, /* KSTRUCT_OFFSET_UCRED_CR_REF */
//    0x00, // 0x18, /* KSTRUCT_OFFSET_UCRED_CR_UID */
//    0x00, // 0x1c, /* KSTRUCT_OFFSET_UCRED_CR_RUID */
//    0x00, // 0x20, /* KSTRUCT_OFFSET_UCRED_CR_SVUID */
//    0x00, // 0x24, /* KSTRUCT_OFFSET_UCRED_CR_NGROUPS */
//    0x00, // 0x28, /* KSTRUCT_OFFSET_UCRED_CR_GROUPS */
//    0x00, // 0x68, /* KSTRUCT_OFFSET_UCRED_CR_RGID */
//    0x00, // 0x6c, /* KSTRUCT_OFFSET_UCRED_CR_SVGID */
//    0x00, // 0x70, /* KSTRUCT_OFFSET_UCRED_CR_GMUID */
//    0x00, // 0x74, /* KSTRUCT_OFFSET_UCRED_CR_FLAGS */
//    0x00, // 0x78, /* KSTRUCT_OFFSET_UCRED_CR_LABEL */
//    0x00, // 0x0, /* KSTRUCT_OFFSET_LABEL_L_FLAGS */
//    0x00, // 0x8, /* KSTRUCT_OFFSET_LABEL_L_PERPOLICY */
//    0x00, // 0x18, /* KSTRUCT_SIZE_IPC_ENTRY */
//    0x00, // 0x8, /* KSTRUCT_OFFSET_IPC_ENTRY_IE_BITS */
//    0x00, // 0x54, /* KSTRUCT_OFFSET_VNODE_V_FLAG */
//    0x00, // 0x50, /* KSTRUCT_OFFSET_UBC_INFO_CSBLOBS */
//    0x00, // 0x10c, /* KSTRUCT_OFFSET_VM_MAP_FLAGS */
//    0x00, // 0x0, /* KSTRUCT_OFFSET_PMAP_CS_CODE_DIRECTORY_TRUST_LEVEL */
//    0x00, // 0x0, /* KSTRUCT_OFFSET_PMAP_CS_CODE_DIRECTORY_REGISTERED */
//    0x00, // 0x48, /* KSTRUCT_OFFSET_NAMECACHE_NC_VP */
//    0x00, // 0x10, /* KSTRUCT_OFFSET_NAMECACHE_NC_CHILD_TQE_NEXT */
//    0x00, // 0x1F, /* KVTABLE_OFFSET_OSDICTIONARY_SETOBJECTWITHCHARP */
//    0x00, // 0x26, /* KVTABLE_OFFSET_OSDICTIONARY_GETOBJECTWITHCHARP */
//    0x00, // 0x23, /* KVTABLE_OFFSET_OSDICTIONARY_MERGE */
//    0x00, // 0x1E, /* KVTABLE_OFFSET_OSARRAY_MERGE */
//    0x00, // 0x20, /* KVTABLE_OFFSET_OSARRAY_REMOVEOBJECT */
//    0x00, // 0x22, /* KVTABLE_OFFSET_OSARRAY_GETOBJECT */
//    0x00, // 0x05, /* KVTABLE_OFFSET_OSOBJECT_RELEASE */
//    0x00, // 0x03, /* KVTABLE_OFFSET_OSOBJECT_GETRETAINCOUNT */
//    0x00, // 0x04, /* KVTABLE_OFFSET_OSOBJECT_RETAIN */
//    0x00, // 0x11, /* KVTABLE_OFFSET_OSSTRING_GETLENGTH */
//    0x00, // 0xdd0, // IOSURFACE_CREATE_OUTSIZE
//    0x00, // 0x28,  // KSTRUCT_OFFSET_IPC_SPACE_IS_TASK
//    0x00, // 0x108,  // KSTRUCT_OFFSET_TASK_ITK_SELF,
//    0x00, // 0xb7, // KVTABLE_OFFSET_GET_EXTERNAL_TRAP_FOR_INDEX,
//    0x00, // 0x6c, /* KFREE_ADDR_OFFSET */
};

uint32_t create_outsize;
uint32_t koffset(enum kernel_offset offset) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[[NSProcessInfo processInfo] processName] isEqual:@""]) {//incomplete
            offsets = kernel_offsets_14_3;
            create_outsize = 0xdd0;
        }
    });
    if (offsets == NULL) {
        return 0;
    }
    return offsets[offset];
}
