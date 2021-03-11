#ifndef THREADEXEC__TE_CALL_H_
#define THREADEXEC__TE_CALL_H_

#include "threadexec/threadexec.h"

/*
 * tx_preserve
 *
 * Description:
 * 	Preserve the state of the thread for TX_PRESERVE and prepare the thread to call functions
 * 	without disturbing critical state.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 *
 * Returns:
 * 	Returns true if successful.
 */
bool tx_preserve(threadexec_t threadexec);

/*
 * tx_preserve_restore
 *
 * Description:
 * 	Restore the state of the preserved thread.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 *
 * Returns:
 * 	Returns true if successful.
 */
bool tx_preserve_restore(threadexec_t threadexec);

/*
 * tx_call_regs
 *
 * Description:
 * 	Call a function in the remote thread. Arguments can only be passed in registers, so the
 * 	number of supported arguments is platform-dependent.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
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
 * 	This function should be preferred to thread_call(). A thread_call() implementation may not
 * 	exist even on supported platforms. By contrast, this function always chooses an appropriate
 * 	implementation as long as the threadexec context has been sufficiently initialized.
 *
 * 	Sufficient initialization on arm64 means that the thread port must be set.
 *
 * 	Sufficient initialization on x86-64 means that the thread port must be set and the shared
 * 	memory region must be established.
 */
bool tx_call_regs(threadexec_t threadexec, void *result, size_t result_size,
		word_t function, unsigned argument_count, const word_t *arguments);

/*
 * tx_call
 *
 * Description:
 * 	Call a function in the remote thread. Arguments can be passed in registers or on the stack.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
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
 * 	This function should be preferred to thread_call_stack().
 */
bool tx_call(threadexec_t threadexec,
		void *result, size_t result_size,
		word_t function, unsigned argument_count,
		const struct threadexec_call_argument *arguments);

#endif
