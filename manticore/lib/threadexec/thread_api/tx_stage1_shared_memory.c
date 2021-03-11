#include "tx_stage1_shared_memory.h"

#if TX_HAVE_THREAD_API

#include "tx_call.h"
#include "tx_init_shmem.h"
#include "tx_log.h"
#include "tx_params.h"
#include "tx_prototypes.h"
#include "tx_stage0_mach_ports.h"
#include "tx_stage0_read_write.h"

#include <assert.h>
#include <malloc/malloc.h>
#include <stdlib.h>


// Get the offset from the start of the XPC shmem object to the memory entry field.
static size_t
xpc_shmem_object_offset_memory_entry() {
	// We could create/parse an XPC shmem object to get the field location, but we'll hardcode
	// it for now.
#if __LP64__
	return 24;
#else
#error 32-bit xpc_shmem_object_offset_memory_entry not implemented
#endif
}

// Get the estimated size of an XPC shmem object.
static size_t
xpc_shmem_object_size(void *xshmem) {
	size_t size = malloc_size(xshmem);
	DEBUG_TRACE(2, "malloc_size(shmem) = %zu", size);
	if (size < 8) {
#if __LP64__
		size = 40;
#else
		// Untested; could be smaller.
		size = 36;
#endif
	}
	return size;
}

// Send some shared memory to be mapped in the remote thread.
static bool
send_shared_memory(threadexec_t threadexec, void *address, size_t size, word_t *remote_address) {
	bool success = false;
	// First create an XPC shmem object.
	void *xshmem = xpc_shmem_create(address, size);
	if (xshmem == NULL) {
		ERROR_CALL(xpc_shmem_create, "%p", xshmem);
		goto fail_0;
	}
	// Get a pointer to the XPC shmem object's memory_entry field so that we can mess around.
	size_t memory_entry_offset = xpc_shmem_object_offset_memory_entry();
	mach_port_t *xshmem_memory_entry = (mach_port_t *)((uint8_t *)xshmem + memory_entry_offset);
	// Get the memory entry.
	mach_port_t memory_entry = *xshmem_memory_entry;
	// Allocate some memory in the remote task so that we can copy in the xshmem object.
	size_t xshmem_size = xpc_shmem_object_size(xshmem);
	word_t malloc_args[1] = { xshmem_size };
	word_t xshmem_remote;
	bool ok = tx_call_regs(threadexec, &xshmem_remote, sizeof(xshmem_remote),
			(word_t) malloc, 1, malloc_args);
	if (!ok) {
		ERROR_REMOTE_CALL(malloc);
		goto fail_1;
	}
	if (xshmem_remote == 0) {
		ERROR_REMOTE_CALL_FAIL(malloc, "%p", (void *)xshmem_remote);
		goto fail_1;
	}
	// Get a remote send right to the memory entry. We should really clean this up when we're
	// done, but we currently don't.
	mach_port_t memory_entry_remote;
	ok = tx_stage1_mach_port_insert_send(threadexec, memory_entry,
			&memory_entry_remote);
	if (!ok) {
		ERROR("Could not copy memory entry port into remote thread");
		goto fail_2;
	}
	// Patch the xshmem object so it will work in the remote thread.
	*xshmem_memory_entry = memory_entry_remote;
	// Copy in the patched memory entry to the remote buffer.
	// NOTE: It would be better and faster to do this by sending a Mach message then reusing
	// inline data, but that is more complicated.
	ok = tx_stage0_write(threadexec, xshmem_remote, xshmem, xshmem_size);
	if (!ok) {
		ERROR("Could not copy XPC shmem object to remote thread");
		goto fail_2;
	}
	// Now we have a remote XPC shmem object that refers to a memory entry for the shared
	// memory we want to map. Call xpc_shmem_map to map it. We can have xpc_shmem_map store the
	// address to the first word of the xshmem object itself.
	word_t xsm_args[2] = { xshmem_remote, xshmem_remote };
	size_t size_remote;
	ok = tx_call_regs(threadexec, &size_remote, sizeof(size_remote),
			(word_t) xpc_shmem_map, 2, xsm_args);
	if (!ok) {
		ERROR_REMOTE_CALL(xpc_shmem_map);
		goto fail_2;
	}
	if (size_remote != size) {
		ERROR("Remote call to %s returned size %zu, expected %zu", "xpc_shmem_map",
				size_remote, size);
		goto fail_2;
	}
	// Awesome! We're mapped! Now let's get the address.
	word_t address_remote;
	ok = tx_stage0_read_word(threadexec, xshmem_remote, &address_remote);
	if (!ok) {
		ERROR("Could not read mapping address from remote thread");
		goto fail_2;
	}
	// Perfect!
	success = true;
	*remote_address = address_remote;
fail_2:;
	// Free the remote allocation.
	word_t free_args[1] = { xshmem_remote };
	tx_call_regs(threadexec, NULL, 0, (word_t) free, 1, free_args);
fail_1:
	// Restore the xshmem object and release it.
	*xshmem_memory_entry = memory_entry;
	xpc_release(xshmem);
fail_0:
	return success;
}

bool
tx_stage1_init_shared_memory(threadexec_t threadexec) {
	bool success = false;
	// First allocate the memory.
	const size_t shmem_size = TX_SHARED_MEMORY_SIZE;
	mach_vm_address_t shmem_address;
	kern_return_t kr = mach_vm_allocate(mach_task_self(), &shmem_address, shmem_size,
			VM_FLAGS_ANYWHERE);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(mach_vm_allocate, "%u", kr);
		goto fail_0;
	}
	threadexec->shmem      = (void *) shmem_address;
	threadexec->shmem_size = shmem_size;
	// Send the memory region to the remote thread.
	bool ok = send_shared_memory(threadexec, threadexec->shmem, shmem_size,
			&threadexec->shmem_remote);
	if (!ok) {
		ERROR("Could not set up shared memory");
		goto fail_0;
	}
	// Test the shared memory if we're debugging.
#if DEBUG_LEVEL(1)
	*(word_t *)((uint8_t *)threadexec->shmem + 0x3210) = 0xaabbccdd;
	word_t remote_word;
	ok = tx_stage0_read_word(threadexec, threadexec->shmem_remote + 0x3210,
			&remote_word);
	assert(ok);
	assert(remote_word == 0xaabbccdd);
#endif
	tx_init_shmem_setup_regions(threadexec);
	// Success!
	success = true;
fail_0:
	return success;
}

#endif
