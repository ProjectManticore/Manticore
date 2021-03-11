#include "tx_internal.h"

#include "task_api/tx_init_task.h"
#include "thread_api/tx_init_thread.h"
#include "tx_call.h"
#include "tx_log.h"
#include "tx_prototypes.h"
#include "tx_utils.h"

#include <assert.h>
#include <stdlib.h>

#define KILL_FLAGS	\
	(TX_KILL_THREAD | TX_KILL_TASK)

#define SUPPORTED_FLAGS	\
	(TX_SUSPEND_THREADS | KILL_FLAGS | TX_SUSPEND | TX_RESUME | TX_BORROW_PORTS \
	 | TX_BARE_THREAD)

// Suspend all the threads in a task, except for the specified one.
static bool
suspend_all_threads_except(task_t task, thread_t except) {
	bool success = false;
	// First suspend the task so that it won't create any more threads.
	kern_return_t kr = task_suspend(task);
	if (kr != KERN_SUCCESS) {
		DEBUG_TRACE(1, "Could not suspend task 0x%x: %u", task, kr);
		goto fail_0;
	}
	// Get a list of all the threads.
	thread_act_array_t threads;
	mach_msg_type_number_t count;
	kr = task_threads(task, &threads, &count);
	if (kr != KERN_SUCCESS) {
		DEBUG_TRACE(1, "Could not get threads of task 0x%x: %u", task, kr);
		goto fail_1;
	}
	// Suspend all the threads and clean up resources.
	for (size_t i = 0; i < count; i++) {
		if (threads[i] != except) {
			thread_suspend(threads[i]);
		}
		mach_port_deallocate(mach_task_self(), threads[i]);
	}
	mach_vm_deallocate(mach_task_self(), (mach_vm_address_t) threads,
			count * sizeof(*threads));
	success = true;
fail_1:
	// Resume the task.
	kr = task_resume(task);
	if (kr != KERN_SUCCESS) {
		DEBUG_TRACE(1, "Could not resume task 0x%x: %u", task, kr);
	}
fail_0:
	return success;
}

bool
tx_init_internal(threadexec_t threadexec) {
	tx_create_flags_t flags = threadexec->flags;
	// We can't both kill and resume or both kill and preserve unless we're performing thread
	// hijacking.
	assert((flags & TX_KILL_THREAD) == 0 || (flags & (TX_RESUME | TX_PRESERVE)) == 0);
	// We can only suspend or preserve if we were passed a thread port.
	assert(threadexec->thread != MACH_PORT_NULL || (flags & (TX_SUSPEND | TX_PRESERVE)) == 0);
	// If we have no thread, then TX_BORROW_THREAD_PORT must be clear or we'll leak a port.
	assert(threadexec->thread != MACH_PORT_NULL || (flags & TX_BORROW_THREAD_PORT) == 0);
	// Suspend implies the thread's suspend count is 0. No suspend implies implies suspend
	// count is 1 if we have a thread.
	if (flags & TX_SUSPEND) {
		assert(thread_get_suspend_count(threadexec->thread) == 0);
	} else if (threadexec->thread != MACH_PORT_NULL) {
		assert(thread_get_suspend_count(threadexec->thread) == 1);
	}
	// Suspend the thread if we are supposed to do that.
	bool ok;
	if (flags & TX_SUSPEND) {
		ok = thread_suspend_and_abort_check(threadexec->thread);
		if (!ok) {
			goto fail_0;
		}
	}
	// If we are supposed to preserve the thread state, do that.
	if (flags & TX_PRESERVE) {
		ok = tx_preserve(threadexec);
		if (!ok) {
			goto fail_1;
		}
	}
	// Try initializing with the task APIs. This function performs its own cleanup on failure.
	ok = tx_init_with_task_api(threadexec);
	if (ok) {
		return true;
	}
	// If that doesn't work and this platform supports the thread APIs, try that. This function
	// performs its own cleanup on failure.
#if TX_HAVE_THREAD_API
	ok = tx_init_with_thread_api(threadexec);
	if (ok) {
		return true;
	}
#endif
	// If we preserved the thread state, restore it.
	if (threadexec->flags & TX_PRESERVE) {
		tx_preserve_restore(threadexec);
	}
	// If we suspended the thread, resume it.
fail_1:
	if (threadexec->flags & TX_SUSPEND) {
		thread_resume_check(threadexec->thread);
	}
fail_0:
	return false;
}

threadexec_t
threadexec_init(task_t task, thread_t thread, tx_create_flags_t flags) {
	// Validate the flags.
	assert((flags & SUPPORTED_FLAGS) == flags);
	// We can't both kill and resume.
	assert((flags & KILL_FLAGS) == 0 || (flags & TX_RESUME) == 0);
	// If we have no thread, then it makes no sense to suspend it now or resume or kill it at
	// the end or to borrow the port or claim that the thread is bare.
	assert(thread != MACH_PORT_NULL || (flags & (TX_SUSPEND | TX_RESUME | TX_KILL_THREAD |
					TX_BORROW_THREAD_PORT | TX_BARE_THREAD)) == 0);
	// Set TX_PRESERVE unless we are killing the thread on exit.
	if (thread != MACH_PORT_NULL && (flags & KILL_FLAGS) == 0) {
		flags |= TX_PRESERVE;
	}
	// If TX_SUSPEND_THREADS was specified, suspend all the other threads in the task. We do
	// this here because it should only happen once.
	if (flags & TX_SUSPEND_THREADS) {
		suspend_all_threads_except(task, thread);
	}
	// Create the basic threadexec.
	threadexec_t threadexec = calloc(1, sizeof(*threadexec));
	assert(threadexec != NULL);
	threadexec->task   = task;
	threadexec->thread = thread;
	threadexec->flags  = flags;
	// Now initialize.
	bool ok = tx_init_internal(threadexec);
	if (!ok) {
		free(threadexec);
		return NULL;
	}
	return threadexec;
}

// Try to kill all the threads in a task.
static bool
kill_threads(task_t task) {
	thread_act_array_t threads;
	mach_msg_type_number_t count;
	kern_return_t kr = task_threads(task, &threads, &count);
	if (kr != KERN_SUCCESS) {
		DEBUG_TRACE(2, "Could not get threads of task 0x%x: %u", task, kr);
		return false;
	}
	for (size_t i = 0; i < count; i++) {
		kr = thread_abort(threads[i]);
		if (kr != KERN_SUCCESS) {
			DEBUG_TRACE(2, "Could not abort thread 0x%x of task 0x%x: %u",
					threads[i], task, kr);
		}
		kr = thread_terminate(threads[i]);
		if (kr != KERN_SUCCESS) {
			DEBUG_TRACE(2, "Could not terminate thread 0x%x of task 0x%x: %u",
					threads[i], task, kr);
		}
		mach_port_deallocate(mach_task_self(), threads[i]);
	}
	mach_vm_deallocate(mach_task_self(), (mach_vm_address_t) threads,
			count * sizeof(*threads));
	return true;
}

void
threadexec_deinit(threadexec_t threadexec) {
	assert(threadexec != NULL);
#if TX_HAVE_THREAD_API
	bool done = false;
	if (tx_supports_task_api(threadexec)) {
		done = tx_deinit_with_task_api(threadexec);
	}
	if (!done) {
		tx_deinit_with_thread_api(threadexec);
	}
#else
	tx_deinit_with_task_api(threadexec);
#endif
	// Restore or terminate the thread.
	if (threadexec->flags & TX_PRESERVE) {
		assert((threadexec->flags & KILL_FLAGS) == 0);
		tx_preserve_restore(threadexec);
	} else if (threadexec->flags & TX_KILL_TASK) {
		DEBUG_TRACE(2, "%s: Terminating task 0x%x", __func__, threadexec->task);
		kern_return_t kr = task_terminate(threadexec->task);
		if (kr != KERN_SUCCESS) {
			DEBUG_TRACE(2, "Could not terminate task 0x%x: %u", threadexec->task, kr);
		}
		kill_threads(threadexec->task);
	} else if (threadexec->flags & TX_KILL_THREAD) {
		DEBUG_TRACE(2, "%s: Terminating thread 0x%x", __func__, threadexec->thread);
		thread_terminate(threadexec->thread);
	}
	// Resume the thread if requested.
	if (threadexec->flags & TX_RESUME) {
		thread_resume_check(threadexec->thread);
	}
	// Deallocate the task and thread ports.
	if ((threadexec->flags & TX_BORROW_THREAD_PORT) == 0) {
		DEBUG_TRACE(2, "%s: Deallocating thread 0x%x", __func__, threadexec->thread);
		mach_port_deallocate(mach_task_self(), threadexec->thread);
	}
	if ((threadexec->flags & TX_BORROW_TASK_PORT) == 0) {
		DEBUG_TRACE(2, "%s: Deallocating task 0x%x", __func__, threadexec->task);
		mach_port_deallocate(mach_task_self(), threadexec->task);
	}
	// Free the struct.
	free(threadexec);
}
