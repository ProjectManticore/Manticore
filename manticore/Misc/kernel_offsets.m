//
//  kernel_offsets.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include "kernel_offsets.h"

//kCFCoreFoundationVersionNumbers for determination of iOS Versions
#ifndef kCFCoreFoundationVersionNumber_iOS_14_0
#define kCFCoreFoundationVersionNumber_iOS_14_0 1751.108
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_14_1
#define kCFCoreFoundationVersionNumber_iOS_14_1 1751.108
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_14_2
#define kCFCoreFoundationVersionNumber_iOS_14_2 1770.106
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_14_3
#define kCFCoreFoundationVersionNumber_iOS_14_3 1770.300
#endif

// Offset templates taken from iOS 13

uint32_t* offsets = NULL;

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
    
    /* struct misc */
        0x10,   // KSTRUCT_OFFSET_SANDBOX_SLOT
};

uint32_t create_outsize;
uint32_t koffset(enum kernel_offset offset) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_3) {
            // fprintf(stdout, "kCFCoreFoundation: %f\n", kCFCoreFoundationVersionNumber_iOS_14_3);
            offsets = kernel_offsets_14_3;
        } else if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_14_3) {
            fprintf(stdout, "Jailbreak not supported; kCFCoreFoundation: %f\n", kCFCoreFoundationVersionNumber);
            offsets = NULL;
        }
    });
    if (offsets == NULL) {
        return 0;
    }
    return offsets[offset];
}
