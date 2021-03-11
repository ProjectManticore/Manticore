#ifndef THREAD_CALL__ARM64__THREAD_CALL_ARM64_H_
#define THREAD_CALL__ARM64__THREAD_CALL_ARM64_H_

#include "thread_call.h"

/*
 * thread_save_state_arm64
 *
 * Description:
 * 	Save full state for the thread so that it can be fully restored at a later point. The
 * 	thread is then reinitialized so that it may be used for function calls.
 */
const void *thread_save_state_arm64(thread_act_t thread);

/*
 * thread_restore_state_arm64
 *
 * Description:
 * 	Restore a thread to its original state and free the state.
 */
bool thread_restore_state_arm64(thread_act_t thread, const void *state);

/*
 * thread_call_arm64
 *
 * Description:
 * 	The thread_call implementation for arm64.
 */
bool thread_call_arm64(thread_act_t thread, void *result, size_t result_size,
		word_t function, unsigned argument_count, const word_t *arguments);

/*
 * thread_call_stack_arm64
 *
 * Description:
 * 	The thread_call_stack implementation for arm64.
 */
bool thread_call_stack_arm64(thread_act_t thread,
		void *local_stack_base, word_t remote_stack_base, size_t stack_size,
		void *result, size_t result_size,
		word_t function, unsigned argument_count,
		const struct threadexec_call_argument *arguments);

#endif
