//
//  headers.m
//  manticore
//
//  Created by 21 on 20.02.21.
//

#import <Foundation/Foundation.h>
#include "kernel_offsets.h"

static unsigned koffsets_ios_14_4[] = {
    /* struct proc */
        0x68,            // KSTRUCT_OFFSET_PROC_PID
        0x10,            // KSTRUCT_OFFSET_PROC_TASK
        0xF0,            // KSTRUCT_OFFSET_PROC_UCRED
        0x280,           // KSTRUCT_OFFSET_PROC_CSFLAGS
        0x3C,            // KSTRUCT_OFFSET_PROC_RGID
        0x38,            // KSTRUCT_OFFSET_PROC_RUID
        0x34,            // KSTRUCT_OFFSET_PROC_GID
        0x30,            // KSTRUCT_OFFSET_PROC_UID
    
    /* struct ucred */
        0x18,            // KSTRUCT_OFFSET_UCRED_CR_UID
        0x1C,            // KSTRUCT_OFFSET_UCRED_CR_RUID
        0x20,            // KSTRUCT_OFFSET_UCRED_CR_SVUID
        0x24,            // KSTRUCT_OFFSET_UCRED_CR_NGROUPS
        0x28,            // KSTRUCT_OFFSET_UCRED_CR_GROUPS
        0x68,            // KSTRUCT_OFFSET_UCRED_CR_RGID
        0x6C,            // KSTRUCT_OFFSET_UCRED_CR_SVGID
        0x78,            // KSTRUCT_OFFSET_UCRED_CR_LABEL
    
    /* struct task */
        0x280,
    
    /* sandbox */
        0x10,
};

static unsigned koffsets_ios_14_3[] = {

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

static unsigned koffsets_ios_misc[] = {
    0x68,       // proc_t::p_pid
    0x10,       // proc_t::task
    0x30,       // proc_t::p_uid
    0x34,       // proc_t::p_uid
    0x38,       // proc_t::p_uid
    0x3c,       // proc_t::p_uid
    0xf0,       // proc_t::p_ucred
    0x280,      // proc_t::p_csflags

    0x18,       // ucred::cr_uid
    0x1c,       // ucred::cr_ruid
    0x20,       // ucred::cr_svuid
    0x24,       // ucred::cr_ngroups
    0x28,       // ucred::cr_groups
    0x68,       // ucred::cr_rgid
    0x6c,       // ucred::cr_svgid
    0x78,       // ucred::cr_label

    0x3a0,      // task::t_flags

    0x10,       // sandbox_slot
};

uint32_t* offsets = NULL;
uint32_t create_outsize;

uint32_t koffset(enum kernel_offset offset) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_3) {
            fprintf(stdout, "kCFCoreFoundation: %f\n", kCFCoreFoundationVersionNumber_iOS_14_3);
            offsets = koffsets_ios_14_3;
        } else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_2){
            fprintf(stdout, "kCFCoreFoundation: %f\n", kCFCoreFoundationVersionNumber_iOS_14_2);
            offsets = koffsets_ios_14_3;
        } else if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_14_3) {
            fprintf(stderr, "Jailbreak not supported; kCFCoreFoundation: %f\n", kCFCoreFoundationVersionNumber);
            offsets = koffsets_ios_misc;
        }
    });
    if (offsets == NULL) {
        return 0;
    }
    return offsets[offset];
}
