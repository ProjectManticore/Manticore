#include "tx_init_thread.h"

#if TX_HAVE_THREAD_API

#include "tx_pthread.h"
#include "tx_call.h"
#include "tx_log.h"
#include "tx_prototypes.h"
#include "tx_pthread.h"
#include "tx_utils.h"
#include "tx_stage0_mach_ports.h"
#include "tx_stage1_shared_memory.h"

#include <assert.h>
#include <stdlib.h>
#include <unistd.h>

// Perform straightforward initialization using a supplied thread port.
static bool
init_with_thread(threadexec_t threadexec) {
	DEBUG_TRACE(1, "Using thread 0x%x", threadexec->thread);
	assert(threadexec->thread != MACH_PORT_NULL);
	// Perform pthread setup if this is a bare thread.
	bool ok;
	if (threadexec->flags & TX_BARE_THREAD) {
		// We assume the thread already has an initialized stack.
		ok = tx_pthread_init_bare_thread(threadexec);
		if (!ok) {
			goto fail;
		}
	}
	// Set up Mach ports to send messages between this task and the remote thread.
	ok = tx_stage0_init_mach_ports(threadexec);
	if (!ok) {
		goto fail;
	}
	// Set up the shared memory region.
	ok = tx_stage1_init_shared_memory(threadexec);
	if (!ok) {
		goto fail;
	}
	// Return success.
	return true;
fail:
	tx_deinit_with_thread_api(threadexec);
	return false;
}

// Pick a thread in the task to hijack.
static thread_t pick_hijack_thread(task_t task) {
	thread_t hijack = MACH_PORT_NULL;
	// Get all the threads in the task.
	thread_act_array_t threads;
	mach_msg_type_number_t thread_count;
	kern_return_t kr = task_threads(task, &threads, &thread_count);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(task_threads, "%u", kr);
		goto fail_0;
	}
	if (thread_count == 0) {
		ERROR("No threads in task 0x%x", task);
		goto fail_1;
	}
	// Find a candidate thread.
	thread_t thread = MACH_PORT_NULL;
	for (long i = thread_count - 1; thread == MACH_PORT_NULL && i >= 0; i--) {
		int suspend_count = thread_get_suspend_count(threads[i]);
		if (suspend_count == 0) {
			thread = threads[i];
			break;
		}
	}
	if (thread == MACH_PORT_NULL) {
		ERROR("No available candidate threads to hijack");
		goto fail_1;
	}
	// Success!
	hijack = thread;
	// Deallocate the thread ports and array.
fail_1:
	for (size_t i = 0; i < thread_count; i++) {
		DEBUG_TRACE(2, "Task 0x%x: thread 0x%x", task, threads[i]);
		if (threads[i] != hijack) {
			mach_port_deallocate(mach_task_self(), threads[i]);
		}
	}
	mach_vm_deallocate(mach_task_self(), (mach_vm_address_t) threads,
			thread_count * sizeof(*threads));
fail_0:
	return hijack;
}

// Hijack and use an existing thread. This is only safe if we'll kill the task anyway, since the
// thread will be totally consumed.
static bool
init_by_hijacking_thread(threadexec_t threadexec) {
	DEBUG_TRACE(1, "Performing thread hijacking");
	assert(threadexec->flags & TX_KILL_TASK);
	assert(threadexec->thread == MACH_PORT_NULL);
	assert((threadexec->flags & (TX_SUSPEND | TX_PRESERVE | TX_RESUME | TX_KILL_THREAD)) == 0);
	// First pick a thread to hijack. The thread is not suspended.
	thread_t hijack = pick_hijack_thread(threadexec->task);
	if (hijack == MACH_PORT_NULL) {
		ERROR("Could not hijack a thread in task 0x%x", threadexec->task);
		return false;
	}
	// Now initialize with that.
	threadexec->flags |= TX_SUSPEND;
	threadexec->thread = hijack;
	return tx_init_internal(threadexec);
}

// When we don't have a thread, we will perform thread hijacking to create one. First, we will
// choose a preexisting thread in the task to hijack, and create a threadexec with that using
// TX_PRESERVE semantics. Then we will use that thread to create a new thread. Once we have the new
// thread, we will replace the original thread in the threadexec struct with the new thread.
static bool
init_without_thread(threadexec_t threadexec) {
	DEBUG_TRACE(1, "Performing temporary thread hijacking");
	ERROR("NOT IMPLEMENTED"); // TODO: There used to be a partial implementation here.
	// TODO: The issue appears to be that the suspend/abort/get_state/set_state/resume sequence
	// doesn't actually perfectly preserve the state of the original thread. Thus, even after
	// setting the state to identically match the original state, the thread will sometimes
	// crash on resume. Unfortunately I don't know any way around this.
	return false;
}

bool
tx_init_with_thread_api(threadexec_t threadexec) {
	DEBUG_TRACE(1, "Using thread API");
	// We use different initialization strategies for when we do and don't have a thread port.
	if (threadexec->thread != MACH_PORT_NULL) {
		return init_with_thread(threadexec);
	} else if (threadexec->flags & TX_KILL_TASK) {
		// The above condition isn't exactly correct: it should really be: "hijack a thread
		// permanently if the user doesn't care about maintaining the integrity of the
		// process", which is even more strict than TX_KILL_TASK.
		return init_by_hijacking_thread(threadexec);
	} else {
		return init_without_thread(threadexec);
	}
}

void
tx_deinit_with_thread_api(threadexec_t threadexec) {
	DEBUG_TRACE(2, "%s", __func__);
	if (threadexec->shmem_size) {
		// Don't bother deallocating the remote memory if we're killing the task.
		if (threadexec->shmem_remote != 0 && (threadexec->flags & TX_KILL_TASK) == 0) {
			DEBUG_TRACE(2, "Deallocating remote shared memory");
			WARNING("NOT IMPLEMENTED"); // TODO: There used to be an incorrect version.
			// Go back to the initial commit to retrieve it.
			// TODO: The problem is we can't deallocate the memory that is our
			// stack or we'll crash! Therefore we need to save the old SP before we set
			// it (implicitly) with a call to thread_call_stack().
		}
		if (threadexec->shmem != NULL) {
			DEBUG_TRACE(2, "Deallocating local shared memory");
			mach_vm_deallocate(mach_task_self(), (mach_vm_address_t) threadexec->shmem,
					threadexec->shmem_size);
			threadexec->shmem = NULL;
		}
		threadexec->shmem_size = 0;
	}
	// TODO: Destroy these ports on the remote end.
	DEBUG_TRACE(2, "Destroying local Mach ports");
	if (threadexec->local_port != MACH_PORT_NULL) {
		mach_port_destroy(mach_task_self(), threadexec->local_port);
		threadexec->local_port = MACH_PORT_NULL;
	}
	if (threadexec->remote_port != MACH_PORT_NULL) {
		mach_port_deallocate(mach_task_self(), threadexec->remote_port);
		threadexec->remote_port = MACH_PORT_NULL;
	}
}

#endif // TX_HAVE_THREAD_API
