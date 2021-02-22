#ifndef KernelOffsets_h
#define KernelOffsets_h

extern uint32_t* offsets;

typedef struct {
    /* struct proc */
        uint32_t KSTRUCT_OFFSET_PROC_PID;
        uint32_t KSTRUCT_OFFSET_PROC_TASK;
        uint32_t KSTRUCT_OFFSET_PROC_UCRED;
        uint32_t KSTRUCT_OFFSET_PROC_CSFLAGS;
        uint32_t KSTRUCT_OFFSET_PROC_RGID;
        uint32_t KSTRUCT_OFFSET_PROC_RUID;
        uint32_t KSTRUCT_OFFSET_PROC_GID;
        uint32_t KSTRUCT_OFFSET_PROC_UID;

    /* struct ucred */
        uint32_t KSTRUCT_OFFSET_UCRED_CR_UID;
        uint32_t KSTRUCT_OFFSET_UCRED_CR_RUID;
        uint32_t KSTRUCT_OFFSET_UCRED_CR_SVUID;
        uint32_t KSTRUCT_OFFSET_UCRED_CR_NGROUPS;
        uint32_t KSTRUCT_OFFSET_UCRED_CR_GROUPS;
        uint32_t KSTRUCT_OFFSET_UCRED_CR_RGID;
        uint32_t KSTRUCT_OFFSET_UCRED_CR_SVGID;
        uint32_t KSTRUCT_OFFSET_UCRED_CR_LABEL;

    /* struct task */
        uint32_t KSTRUCT_OFFSET_TASK_TFLAGS;
    /* sandbox */
        uint32_t KSTRUCT_OFFSET_SANDBOX_SLOT;
    /* kernel */
        uint32_t KSTRUCT_OFFSET_KERNEL_MAP;
} kernel_offset_array;

kernel_offset_array dynamic_koffsets_ios_14_4(void);

enum kernel_offset {
    /* struct proc */
        KSTRUCT_OFFSET_PROC_PID,
        KSTRUCT_OFFSET_PROC_TASK,
        KSTRUCT_OFFSET_PROC_UCRED,
        KSTRUCT_OFFSET_PROC_CSFLAGS,
        KSTRUCT_OFFSET_PROC_RGID,
        KSTRUCT_OFFSET_PROC_RUID,
        KSTRUCT_OFFSET_PROC_GID,
        KSTRUCT_OFFSET_PROC_UID,
    
    /* struct ucred */
        KSTRUCT_OFFSET_UCRED_CR_UID,
        KSTRUCT_OFFSET_UCRED_CR_RUID,
        KSTRUCT_OFFSET_UCRED_CR_SVUID,
        KSTRUCT_OFFSET_UCRED_CR_NGROUPS,
        KSTRUCT_OFFSET_UCRED_CR_GROUPS,
        KSTRUCT_OFFSET_UCRED_CR_RGID,
        KSTRUCT_OFFSET_UCRED_CR_SVGID,
        KSTRUCT_OFFSET_UCRED_CR_LABEL,
    
    /* struct task */
        KSTRUCT_OFFSET_TASK_TFLAGS,
    
    /* struct misc */
        KSTRUCT_OFFSET_SANDBOX_SLOT
};

uint32_t koffset(enum kernel_offset offset);

#endif
