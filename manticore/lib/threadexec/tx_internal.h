#ifndef THREADEXEC__TX_INTERNAL_H_
#define THREADEXEC__TX_INTERNAL_H_

#include "threadexec/threadexec.h"

/*
 * macro TX_HAVE_THREAD_API
 *
 * Description:
 * 	Whether we have a functional thread-based function calling API. This depends almost
 * 	entirely on the existence of a thread_call() implementation for the platform: with
 * 	thread_call(), we can probably bootstrap a full threadexec implementation; without
 * 	thread_call(), we probably need to rely on the Mach task APIs.
 */
#if __arm64__
#define TX_HAVE_THREAD_API 1
#endif

// More flags.
enum {
	// Restore the thread state in threadexec_deinit(). This is the default unless
	// TX_KILL_THREAD or TX_KILL_TASK is supplied.
	TX_PRESERVE = 0x10000,
};

// The threadexec struct.
struct threadexec {
	// The task in which we are executing. This may be a task_t or a task_inspect_t or
	// MACH_PORT_NULL.
	task_t task;
	task_t task_remote;
	// The thread on which we are executing. This will be suspended if not currently executing.
	thread_t thread;
	thread_t thread_remote;
	// The creation flags.
	tx_create_flags_t flags;
	// Whether the task APIs work on this instance. Only available if we have the thread API
	// too.
#if TX_HAVE_THREAD_API
	bool task_api;
#endif
	// The local and remote ends of a local receive port, for sending messages from the remote
	// thread to the local task.
	mach_port_t local_port;
	mach_port_t local_port_remote;
	// The local and remote ends of a remote receive port, for sending messages from the local
	// task to the remote thread.
	mach_port_t remote_port;
	mach_port_t remote_port_remote;
	// The shared memory region. The lower half of this is the stack (growing downwards) and
	// the upper half is usable for clients.
	void *shmem;
	word_t shmem_remote;
	size_t shmem_size;
	// The remote thread's stack. This is part of the shared memory region, allowing us to
	// directly modify the remote thread's stack to set up arguments before execution. The
	// stack_base field points to the base address of the stack, which is the point from which
	// the stack grows downwards. It is just off the high end of the stack.
	void *stack_base;
	word_t stack_base_remote;
	size_t stack_size;
	// The client portion of the shared memory region.
	void *client_shmem;
	word_t client_shmem_remote;
	size_t client_shmem_size;
	// The saved thread state, if this thread is being preserved (TX_PRESERVE).
	const void *preserve_state;
};

/*
 * tx_supports_task_api
 *
 * Description:
 * 	A convenience function to test if the threadexec instance supports the task API.
 */
static inline bool
tx_supports_task_api(struct threadexec *threadexec) {
#if TX_HAVE_THREAD_API
	return threadexec->task_api;
#else
	return true;
#endif
}

/*
 * tx_init_internal
 *
 * Description:
 * 	This is the true initialization routine. It is useful for thread hijacking to initialize
 * 	twice. Only task, thread, and flags need to be initialized.
 */
bool tx_init_internal(threadexec_t threadexec);

#endif
