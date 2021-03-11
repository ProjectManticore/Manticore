#include "tx_internal.h"

#include "tx_log.h"
#include "tx_prototypes.h"

#include <assert.h>

void
threadexec_shared_vm_default(threadexec_t threadexec,
		const void **remote_address, void **local_address, size_t *size) {
	if (remote_address != NULL) {
		*remote_address = (const void *) threadexec->client_shmem_remote;
	}
	if (local_address != NULL) {
		*local_address = threadexec->client_shmem;
	}
	if (size != NULL) {
		*size = threadexec->client_shmem_size;
	}
}

// Try to map the shared memory into the remote task using the Mach task APIs.
// NOTE: This routine does not need any further initialization than the task port.
static bool
map_shared_memory_with_task_api(threadexec_t threadexec, mach_port_t memory_entry, size_t size,
		const void **remote_address) {
	assert(tx_supports_task_api(threadexec));
	mach_vm_address_t remote_map_address = 0;
	kern_return_t kr = mach_vm_map(threadexec->task,
			&remote_map_address,
			size,
			0,
			VM_FLAGS_ANYWHERE,
			memory_entry,
			0,
			FALSE,
			VM_PROT_DEFAULT,
			VM_PROT_DEFAULT,
			VM_INHERIT_NONE);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(mach_vm_map, "%u", kr);
		return false;
	}
	*remote_address = (void *) remote_map_address;
	return true;
}

#if TX_HAVE_THREAD_API

// NOTE: This routine needs Mach ports and shmem to already be initialized.
static bool
map_shared_memory_with_thread_api(threadexec_t threadexec, mach_port_t memory_entry, size_t size,
		const void **remote_address) {
	bool success = false;
	// Send the memory entry to the remote thread.
	mach_port_name_t remote_memory_entry;
	bool ok = threadexec_mach_port_insert(threadexec, memory_entry, &remote_memory_entry,
			MACH_MSG_TYPE_COPY_SEND);
	if (!ok) {
		goto fail_0;
	}
	// Now map the memory entry into the remote task with a remote call to mach_vm_map.
	word_t remote_address_out = threadexec->shmem_remote;
	const void **remote_address_out_local  = threadexec->shmem;
	struct threadexec_call_argument vm_map_args[11] = {
		TX_ARG(vm_map_t,               threadexec->task_remote),
		TX_ARG(mach_vm_address_t *,    remote_address_out),
		TX_ARG(mach_vm_size_t,         size),
		TX_ARG(mach_vm_offset_t,       0),
		TX_ARG(int,                    VM_FLAGS_ANYWHERE),
		TX_ARG(mem_entry_name_port_t,  remote_memory_entry),
		TX_ARG(memory_object_offset_t, 0),
		TX_ARG(boolean_t,              FALSE),
		TX_ARG(vm_prot_t,              VM_PROT_DEFAULT),
		TX_ARG(vm_prot_t,              VM_PROT_DEFAULT),
		TX_ARG(vm_inherit_t,           VM_INHERIT_NONE),
	};
	kern_return_t kr;
	ok = threadexec_call(threadexec, &kr, sizeof(kr), mach_vm_map, 11, vm_map_args);
	if (!ok) {
		ERROR_REMOTE_CALL(mach_vm_map);
		goto fail_1;
	}
	if (kr != KERN_SUCCESS) {
		ERROR_REMOTE_CALL_FAIL(mach_vm_map, "%u", kr);
		goto fail_1;
	}
	// Return the remote address of the mapping.
	*remote_address = *remote_address_out_local;
	success = true;
fail_1:;
	struct threadexec_call_argument port_dealloc_args[2] = {
		TX_ARG(task_t,      threadexec->task_remote),
		TX_ARG(mach_port_t, remote_memory_entry),
	};
	threadexec_call(threadexec, NULL, 0, mach_port_deallocate, 2, port_dealloc_args);
fail_0:
	return success;
}

#endif // TX_HAVE_THREAD_API

// NOTE: If the threadexec supports the task API, then only the task port needs to be initialized.
bool
threadexec_shared_vm_allocate(threadexec_t threadexec,
		const void **remote_address, void **local_address, size_t size) {
	bool success = false;
	// First allocate some memory locally.
	mach_vm_address_t local_vm_address;
	kern_return_t kr = mach_vm_allocate(mach_task_self(), &local_vm_address, size,
			VM_FLAGS_ANYWHERE);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(mach_vm_allocate, "%u", kr);
		goto fail_0;
	}
	// Create a memory entry for this allocation.
	memory_object_size_t mo_size = size;
	mach_port_t memory_entry = MACH_PORT_NULL;
	kr = mach_make_memory_entry_64(mach_task_self(), &mo_size,
			(memory_object_offset_t) local_vm_address, VM_PROT_DEFAULT, &memory_entry,
			MACH_PORT_NULL);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(mach_make_memory_entry_64, "%u", kr);
		goto fail_1;
	}
	DEBUG_TRACE(1, "memory_entry = %x", memory_entry);
	// Try to map this memory entry in the remote task. Prefer the task API but default to the
	// thread API.
	bool ok;
	if (tx_supports_task_api(threadexec)) {
		ok = map_shared_memory_with_task_api(threadexec, memory_entry, size,
				remote_address);
		if (ok) {
			goto success;
		}
	}
#if TX_HAVE_THREAD_API
	ok = map_shared_memory_with_thread_api(threadexec, memory_entry, size, remote_address);
	if (ok) {
		goto success;
	}
#endif
	goto fail_2;
	// Success!
success:
	*local_address  = (void *) local_vm_address;
	success = true;
fail_2:
	mach_port_deallocate(mach_task_self(), memory_entry);
fail_1:
	if (!success) {
		mach_vm_deallocate(mach_task_self(), local_vm_address, size);
	}
fail_0:
	return success;
}

bool
threadexec_mach_vm_deallocate(threadexec_t threadexec,
		const void *remote_address, size_t size) {
	struct threadexec_call_argument vm_dealloc_args[3] = {
		TX_ARG(vm_map_t,          threadexec->task_remote),
		TX_ARG(mach_vm_address_t, remote_address),
		TX_ARG(mach_vm_size_t,    size),
	};
	bool ok = threadexec_call(threadexec, NULL, 0, mach_vm_deallocate,
			3, vm_dealloc_args);
	if (!ok) {
		ERROR_REMOTE_CALL(mach_vm_deallocate);
	}
	return ok;
}

void
threadexec_shared_vm_deallocate(threadexec_t threadexec,
		const void *remote_address, void *local_address, size_t size) {
	threadexec_mach_vm_deallocate(threadexec, remote_address, size);
	mach_vm_deallocate(mach_task_self(), (mach_vm_address_t) local_address, size);
}
