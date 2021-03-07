#ifndef KernelOffsets_h
#define KernelOffsets_h

#define HARDCODED_kernel_base_addr 0xFFFFFFF007004000
#define HARDCODED_kernel_map_addr 0xfffffff0076c0918

extern uint32_t* offsets;

typedef struct {
    /* struct kernel */
        uint32_t KSTRUCT_OFFSET_KERNTASK_MAP;
    /* struct proc */
        uint32_t KSTRUCT_OFFSET_PROC_PID;
        uint32_t KSTRUCT_OFFSET_PROC_TASK;
        uint32_t KSTRUCT_OFFSET_PROC_UCRED;
        uint32_t KSTRUCT_OFFSET_PROC_CSFLAGS;
        uint32_t KSTRUCT_OFFSET_PROC_RGID;
        uint32_t KSTRUCT_OFFSET_PROC_RUID;
        uint32_t KSTRUCT_OFFSET_PROC_GID;
        uint32_t KSTRUCT_OFFSET_PROC_UID;
        uint32_t KSTRUCT_OFFSET_PROC_P_FD;
    /* struct ipc_port */
        uint32_t KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT;
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
    /* misc/desc */
        uint32_t KSTRUCT_OFFSET_FILEDESC_FD_OFILES;
        uint32_t KSTRUCT_OFFSET_FILEPROC_F_FGLOB;
        uint32_t KSTRUCT_OFFSET_FILEGLOB_FG_DATA;
} kernel_offset_array;

kernel_offset_array dynamic_koffsets_ios_14_4(void);

enum kernel_offset {
    /* struct kernel */
        KSTRUCT_OFFSET_KERNTASK_MAP,
    /* struct proc */
        KSTRUCT_OFFSET_PROC_PID,
        KSTRUCT_OFFSET_PROC_TASK,
        KSTRUCT_OFFSET_PROC_UCRED,
        KSTRUCT_OFFSET_PROC_CSFLAGS,
        KSTRUCT_OFFSET_PROC_RGID,
        KSTRUCT_OFFSET_PROC_RUID,
        KSTRUCT_OFFSET_PROC_GID,
        KSTRUCT_OFFSET_PROC_UID,
        KSTRUCT_OFFSET_PROC_P_FD,
    /* struct ipc_port */
        KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT,
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
        KSTRUCT_OFFSET_SANDBOX_SLOT,
    /* kernel */
        KSTRUCT_OFFSET_KERNEL_MAP,
    /* misc/desc */
        KSTRUCT_OFFSET_FILEDESC_FD_OFILES,
        KSTRUCT_OFFSET_FILEPROC_F_FGLOB,
        KSTRUCT_OFFSET_FILEGLOB_FG_DATA
};

#ifdef __cplusplus
extern "C" {
#endif

uint32_t koffset(enum kernel_offset offset);

#ifdef __cplusplus
}
#endif

#endif
