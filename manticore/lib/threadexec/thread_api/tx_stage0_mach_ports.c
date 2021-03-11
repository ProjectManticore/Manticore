#include "tx_stage0_mach_ports.h"

#if TX_HAVE_THREAD_API

#include "tx_call.h"
#include "tx_log.h"
#include "tx_utils.h"

// This isn't declared in any headers.
extern mach_port_name_t mach_reply_port(void);

// Get the remote thread's name for itself. The only initialized field of threadexec we can rely on
// is the thread port.
static bool
get_thread_remote(threadexec_t threadexec) {
	// Call mach_thread_self() to get the remote thread port name. This adds another send right
	// to the thread port in the remote thread, but we don't really care.
	thread_t thread_remote;
	bool ok = tx_call_regs(threadexec, &thread_remote, sizeof(thread_remote),
			(word_t) mach_thread_self, 0, NULL);
	if (!ok) {
		ERROR_REMOTE_CALL(mach_thread_self);
		return false;
	}
	threadexec->thread_remote = thread_remote;
	DEBUG_TRACE(2, "thread_remote = %x", thread_remote);
	return true;
}

// When this function is called, threadexec only has a valid thread port. We need to use our thread
// execute primitive to set up a Mach port from which the remote thread can send messages to us.
// A convenient trick we can use is to stash a send right to our local port in the remote thread's
// THREAD_KERNEL_PORT special port, so that the remote thread can retrieve the send right with a
// call to mach_thread_self().
static bool
set_up_local_port(threadexec_t threadexec) {
	bool success = false;
	// Allocate a new receive right with a send right This will be the local port. We don't
	// need to clean up after it on later failure since that will be handled in
	// tx_deinit_with_thread_api().
	mach_port_t local_port = mach_port_allocate_receive_and_send();
	if (local_port == MACH_PORT_NULL) {
		goto fail_0;
	}
	threadexec->local_port = local_port;
	DEBUG_TRACE(2, "local_port = %x", local_port);
	// Push the send right to the remote thread.
	bool ok = tx_stage1_mach_port_insert_send(threadexec, local_port,
			&threadexec->local_port_remote);
	if (!ok) {
		goto fail_0;
	}
	// Success!
	success = true;
fail_0:
	return success;
}

// Now we need to set up a remote port and pass a send right to that port back to the local task.
// We need thread, task_remote, and thread_remote.
static bool
set_up_remote_port(threadexec_t threadexec) {
	bool success = false;
	// First call mach_reply_port() in the remote task to create a Mach port on which the
	// remote thread can receive messages. This is simpler than the (mostly equivalent) call to
	// mach_port_allocate().
	mach_port_t remote_port_remote;
	bool ok = tx_call_regs(threadexec, &remote_port_remote, sizeof(remote_port_remote),
			(word_t) mach_reply_port, 0, NULL);
	if (!ok) {
		ERROR_REMOTE_CALL(mach_reply_port);
		goto fail_0;
	}
	DEBUG_TRACE(2, "remote_port_remote = %x", remote_port_remote);
	if (remote_port_remote == MACH_PORT_NULL) {
		ERROR("Could not allocate Mach port in remote thread");
		goto fail_0;
	}
	threadexec->remote_port_remote = remote_port_remote;
	// Add a send right to the remote port we just allocated.
	kern_return_t kr;
	word_t mpir_arguments[4] = {
		threadexec->task_remote, remote_port_remote, remote_port_remote,
		MACH_MSG_TYPE_MAKE_SEND
	};
	ok = tx_call_regs(threadexec, &kr, sizeof(kr),
			(word_t) mach_port_insert_right, 4, mpir_arguments);
	if (!ok) {
		ERROR_REMOTE_CALL(mach_port_insert_right);
		goto fail_0;
	}
	if (kr != KERN_SUCCESS) {
		ERROR_REMOTE_CALL_FAIL(mach_port_insert_right, "%u", kr);
		goto fail_0;
	}
	// Store the remote port in the thread's THREAD_KERNEL_PORT special port.
	word_t tssp_arguments[3] = {
		threadexec->thread_remote, THREAD_KERNEL_PORT, remote_port_remote
	};
	ok = tx_call_regs(threadexec, &kr, sizeof(kr),
			(word_t) thread_set_special_port, 3, tssp_arguments);
	if (!ok) {
		ERROR_REMOTE_CALL(thread_set_special_port);
		goto fail_0;
	}
	if (kr != KERN_SUCCESS) {
		ERROR_REMOTE_CALL_FAIL(thread_set_special_port, "%u", kr);
		goto fail_0;
	}
	// Retrieve the stored remote port using thread_get_special_port(), which will give us a
	// send right to the remote thread's port.
	mach_port_t remote_port;
	kr = thread_get_special_port(threadexec->thread, THREAD_KERNEL_PORT, &remote_port);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(thread_get_special_port, "%u", kr);
		goto fail_0;
	}
	threadexec->remote_port = remote_port;
	DEBUG_TRACE(2, "remote_port = %x", remote_port);
	// Restore the remote thread's THREAD_KERNEL_PORT special port.
	kr = thread_set_special_port(threadexec->thread, THREAD_KERNEL_PORT, threadexec->thread);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(thread_set_special_port, "%u", kr);
		goto fail_0;
	}
	// Success!
	success = true;
fail_0:
	return success;
}

// This actually doesn't need all of stage1. :)
bool
tx_stage1_mach_port_insert_send(threadexec_t threadexec,
		mach_port_t local_port, mach_port_name_t *remote_port_name) {
	bool success = false;
	// Get the original THREAD_KERNEL_PORT (the only special port that's defined for a thread).
	// This should be exactly the same as the thread right we already have.
	mach_port_t thread_kernel_port;
	kern_return_t kr = thread_get_special_port(threadexec->thread, THREAD_KERNEL_PORT,
			&thread_kernel_port);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(thread_get_special_port, "%u", kr);
		goto fail_0;
	}
	DEBUG_TRACE(2, "thread = %x, thread_kernel_port = %x", threadexec->thread,
			thread_kernel_port);
	// Set the local port as the remote thread's kernel port.
	kr = thread_set_special_port(threadexec->thread, THREAD_KERNEL_PORT, local_port);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(thread_set_special_port, "%u", kr);
		goto fail_1;
	}
	// Call mach_thread_self on the remote thread to get the remote name for our local
	// port. We should really call thread_get_special_port() but that's a little more
	// complicated so we rely on the fact that they both return the same thing.
	mach_port_t local_port_remote;
	bool ok = tx_call_regs(threadexec, &local_port_remote, sizeof(local_port_remote),
			(word_t) mach_thread_self, 0, NULL);
	if (!ok) {
		ERROR_REMOTE_CALL(mach_thread_self);
		thread_set_special_port(threadexec->thread, THREAD_KERNEL_PORT,
				thread_kernel_port);
		goto fail_1;
	}
	DEBUG_TRACE(2, "local_port_remote = %x", local_port_remote);
	// Restore the original value of the thread's kernel port.
	kr = thread_set_special_port(threadexec->thread, THREAD_KERNEL_PORT, thread_kernel_port);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(thread_set_special_port, "%u", kr);
		goto fail_1;
	}
	// Success!
	success = true;
	*remote_port_name = local_port_remote;
fail_1:
	mach_port_deallocate(mach_task_self(), thread_kernel_port);
fail_0:
	return success;
}

bool
tx_stage0_init_mach_ports(threadexec_t threadexec) {
	// We will just assume that the remote task's own task port name is the same as ours. This
	// is pretty much always the case: it should have the value 0x103.
	threadexec->task_remote = mach_task_self();
	// If we fail, cleanup will happen in threadexec_deinit_internal().
	return get_thread_remote(threadexec)
		&& set_up_local_port(threadexec)
		&& set_up_remote_port(threadexec);
}

#endif // TX_HAVE_THREAD_API
