#ifndef THREADEXEC__TX_PROTOTYPES_H_
#define THREADEXEC__TX_PROTOTYPES_H_

#include <mach/mach.h>

#if __x86_64__

#include <mach/mach_vm.h>
#include <xpc/xpc.h>

#else

extern void *xpc_shmem_create(void *region, size_t length);

extern size_t xpc_shmem_map(void *xshmem, void **region);

extern void xpc_release(void *object);

extern
kern_return_t mach_vm_allocate
(
	vm_map_t target,
	mach_vm_address_t *address,
	mach_vm_size_t size,
	int flags
);

extern
kern_return_t mach_vm_deallocate
(
	vm_map_t target,
	mach_vm_address_t address,
	mach_vm_size_t size
);

extern
kern_return_t mach_vm_read_overwrite
(
	vm_map_t target_task,
	mach_vm_address_t address,
	mach_vm_size_t size,
	mach_vm_address_t data,
	mach_vm_size_t *outsize
);

extern
kern_return_t mach_vm_map
(
	vm_map_t target_task,
	mach_vm_address_t *address,
	mach_vm_size_t size,
	mach_vm_offset_t mask,
	int flags,
	mem_entry_name_port_t object,
	memory_object_offset_t offset,
	boolean_t copy,
	vm_prot_t cur_protection,
	vm_prot_t max_protection,
	vm_inherit_t inheritance
);

#endif

#endif
