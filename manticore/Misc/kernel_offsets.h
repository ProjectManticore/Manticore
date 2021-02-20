//
//  headers.h
//  manticore
//
//  Created by 21 on 20.02.21.
//

#ifndef headers_h
#define headers_h

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

enum koffsets_misc {
    /* struct proc */
        off_p_pid,
        off_task,
        off_p_uid,
        off_p_gid,
        off_p_ruid,
        pff_p_rgid,
        off_p_ucred,
        off_p_csflags,
    
    /* struct ucred */
        off_ucred_cr_uid,
        off_ucred_cr_ruid,
        off_ucred_cr_svuid,
        off_ucred_cr_ngroups,
        off_ucred_cr_groups,
        off_ucred_cr_rgid,
        off_ucred_cr_svgid,
        off_ucred_cr_label,
    
    /* struct task */
        off_t_flags,
    
    /* struct misc */
        off_sandbox_slot
};


enum kernel_offset {
    /* struct proc */
        KSTRUCT_OFFSET_PROC_PID,             // KSTRUCT_OFFSET_PROC_PID
        KSTRUCT_OFFSET_PROC_TASK,            // KSTRUCT_OFFSET_PROC_TASK
        KSTRUCT_OFFSET_PROC_UCRED,           // KSTRUCT_OFFSET_PROC_UCRED
        KSTRUCT_OFFSET_PROC_CSFLAGS,         // KSTRUCT_OFFSET_PROC_CSFLAGS
        KSTRUCT_OFFSET_PROC_RGID,            // KSTRUCT_OFFSET_PROC_RGID
        KSTRUCT_OFFSET_PROC_RUID,            // KSTRUCT_OFFSET_PROC_RUID
        KSTRUCT_OFFSET_PROC_GID,             // KSTRUCT_OFFSET_PROC_GID
        KSTRUCT_OFFSET_PROC_UID,             // KSTRUCT_OFFSET_PROC_UID
    /* struct ucred */
        KSTRUCT_OFFSET_UCRED_CR_UID,         // KSTRUCT_OFFSET_UCRED_CR_UID
        KSTRUCT_OFFSET_UCRED_CR_RUID,        // KSTRUCT_OFFSET_UCRED_CR_RUID
        KSTRUCT_OFFSET_UCRED_CR_SVUID,       // KSTRUCT_OFFSET_UCRED_CR_SVUID
        KSTRUCT_OFFSET_UCRED_CR_NGROUPS,     // KSTRUCT_OFFSET_UCRED_CR_NGROUPS
        KSTRUCT_OFFSET_UCRED_CR_GROUPS,      // KSTRUCT_OFFSET_UCRED_CR_GROUPS
        KSTRUCT_OFFSET_UCRED_CR_RGID,        // KSTRUCT_OFFSET_UCRED_CR_RGID
        KSTRUCT_OFFSET_UCRED_CR_SVGID,       // KSTRUCT_OFFSET_UCRED_CR_SVGID
        KSTRUCT_OFFSET_UCRED_CR_LABEL,       // KSTRUCT_OFFSET_UCRED_CR_LABEL
    
    /* struct task */
        KSTRUCT_OFFSET_TASK_TFLAGS,
    
    /* sandbox */
        KSTRUCT_OFFSET_SANDBOX_SLOT
};

extern uint32_t* offsets;
uint32_t koffset(enum kernel_offset offset);

#endif /* headers_h */
