//
//  k_offsets.h
//  ios-fuzzer
//
//  Created by Quote on 2021/1/26.
//  Copyright © 2021 Quote. All rights reserved.
//

#ifndef k_offsets_h
#define k_offsets_h

// Generate the name for an offset.
#define OFFSET(base_, object_)      _##base_##__##object_##__offset_

// Generate the name for the size of an object.
#define SIZE(object_)               _##object_##__size_
typedef uint64_t kptr_t;
#ifdef Q_INTERNAL
#define qexternal
#else
#define qexternal extern
#endif

// Parameters for ipc_entry.
qexternal size_t SIZE(ipc_entry);
qexternal size_t OFFSET(ipc_entry, ie_object);

// Parameters for ipc_port.
qexternal size_t OFFSET(ipc_port, ip_bits);
qexternal size_t OFFSET(ipc_port, ip_references);
qexternal size_t OFFSET(ipc_port, ip_kobject);

// Parameters for struct ipc_space.
qexternal size_t OFFSET(ipc_space, is_table_size);
qexternal size_t OFFSET(ipc_space, is_table);
qexternal size_t OFFSET(thread, jop_pid); // struct thread { struct machine_thread { jop_pid } }

// Parameters for struct task.
qexternal size_t OFFSET(task, map);
qexternal size_t OFFSET(task, itk_space);
qexternal size_t OFFSET(task, bsd_info);
qexternal size_t OFFSET(task, t_flags);

// Parameters for proc
qexternal size_t OFFSET(proc, le_next);
qexternal size_t OFFSET(proc, le_prev);
qexternal size_t OFFSET(proc, task);
qexternal size_t OFFSET(proc, p_ucred);
qexternal size_t OFFSET(proc, p_pid);
qexternal size_t OFFSET(proc, p_fd);
qexternal size_t OFFSET(proc, csflags);
qexternal size_t OFFSET(proc, gid);
qexternal size_t OFFSET(proc, rgid);
qexternal size_t OFFSET(proc, uid);
qexternal size_t OFFSET(proc, ruid);
qexternal size_t OFFSET(proc, pid);

qexternal size_t OFFSET(filedesc, fd_ofiles);
qexternal size_t OFFSET(fileproc, fp_glob);
qexternal size_t OFFSET(fileglob, fg_data);
qexternal size_t OFFSET(pipe, buffer);

// Parameters for ucred
qexternal size_t OFFSET(ucred, cr_posix);
qexternal size_t OFFSET(ucred, cr_uid);
qexternal size_t OFFSET(ucred, cr_svuid);
qexternal size_t OFFSET(ucred, cr_ngroups);
qexternal size_t OFFSET(ucred, cr_groups);
qexternal size_t OFFSET(ucred, cr_svgid);
qexternal size_t OFFSET(ucred, cr_rgid);
qexternal size_t OFFSET(ucred, cr_label);

qexternal size_t SIZE(posix_cred);

// Parameters for OSDictionary.
qexternal size_t OFFSET(OSDictionary, count);
qexternal size_t OFFSET(OSDictionary, capacity);
qexternal size_t OFFSET(OSDictionary, dictionary);

// Parameters for OSString.
qexternal size_t OFFSET(OSString, string);

// Parameters for IOSurfaceRootUserClient.
qexternal size_t OFFSET(IOSurfaceRootUserClient, surfaceClients);
qexternal size_t OFFSET(IOSurfaceClient, surface);
qexternal size_t OFFSET(IOSurface, values);

// Parameters for VNode/VMount.
qexternal size_t OFFSET(vnode, vmount);

qexternal kptr_t kc_kernel_base;
qexternal kptr_t kc_kernel_map;
qexternal kptr_t kc_kernel_task;
qexternal kptr_t kc_IOSurfaceClient_vt;
qexternal kptr_t kc_IOSurfaceClient_vt_0;

#undef qexternal

#ifdef __cplusplus
extern "C" {
#endif

void kernel_offsets_init(void);

#ifdef __cplusplus
}
#endif

#endif /* k_offsets_h */
