#ifndef THREADEXEC__THREAD_CALL_H_
#define THREADEXEC__THREAD_CALL_H_

#include "threadexec/threadexec.h"

#include <mach/mach_types.h>
#include <stdbool.h>

/*
 * thread_save_state
 *
 * Description:
 * 	Save full state information for the thread so that it can be restored later. Also
 * 	reinitialize the thread so that it can be hijacked for function calls.
 *
 * Parameters:
 * 	thread				The thread whose state to save. The thread will also be
 * 					reinitialized.
 *
 * Returns:
 * 	Returns an opaque value containing the original state of the thread. Pass this value to
 * 	thread_restore() to restore the state. If saving the state and reinitializing the thread
 * 	failed, NULL is returned.
 */
const void *thread_save_state(thread_act_t thread);

/*
 * thread_restore_state
 *
 * Description:
 * 	Restore the full state saved earlier with thread_save(). This restores the original thread
 * 	(without resuming it) and frees the state object.
 *
 * Parameters:
 * 	thread				The thread whose state to restore.
 * 	state				The state object returned by thread_save().
 *
 * Returns:
 * 	Returns true if the thread's state was successfully restored.
 */
bool thread_restore_state(thread_act_t thread, const void *state);

/*
 * thread_call
 *
 * Description:
 * 	Call a function in the remote thread. Arguments can only be passed in registers, so the
 * 	number of supported arguments is platform-dependent.
 *
 * Parameters:
 * 	thread				The thread on which to perform the function call.
 * 	result			out	On return, contains the return value of the called
 * 					function.
 * 	result_size			The size of the function's return value in bytes. Must be a
 * 					power of 2 no greater than the platform word size.
 * 	function			The address of the remote function to execute. Pass 0 to
 * 					test if the specified function call would be supported.
 * 	argument_count			The number of arguments to the function.
 * 	arguments			The array of arguments to the function.
 *
 * Returns:
 * 	Returns true on success.
 *
 * Notes:
 * 	The thread must be suspended before this function is called and will be returned in a
 * 	suspended state.
 *
 * 	This function simply delegates to the corresponding implementation for the platform; there
 * 	may not be an implementation on all platforms. In particular, there is no implementation of
 * 	this function for x86-64.
 */
bool thread_call(thread_act_t thread, void *result, size_t result_size,
		word_t function, unsigned argument_count, const word_t *arguments);

/*
 * thread_call_stack
 *
 * Description:
 * 	Call a function in the remote thread. Arguments can be passed in registers or on the stack.
 *
 * Parameters:
 * 	thread				The thread on which to perform the function call.
 * 	local_stack_base		The local address of a shared memory region for the remote
 * 					stack. This is the top address of the stack.
 * 	remote_stack_base		The remote address of the shared stack base.
 * 	stack_size			The number of bytes the stack can grow.
 * 	result			out	On return, contains the return value of the called
 * 					function.
 * 	result_size			The size of the function's return value in bytes. Must be a
 * 					power of 2 no greater than the platform word size.
 * 	function			The address of the remote function to execute. Pass 0 to
 * 					test if the specified function call would be supported.
 * 	argument_count			The number of arguments to the function.
 * 	arguments			The array of arguments to the function.
 *
 * Returns:
 * 	Returns true on success.
 *
 * Notes:
 * 	The thread must be suspended before this function is called and will be returned in a
 * 	suspended state.
 *
 * 	This function simply delegates to the corresponding implementation for the platform.
 */
bool thread_call_stack(thread_act_t thread,
		void *local_stack_base, word_t remote_stack_base, size_t stack_size,
		void *result, size_t result_size,
		word_t function, unsigned argument_count,
		const struct threadexec_call_argument *arguments);

#endif
