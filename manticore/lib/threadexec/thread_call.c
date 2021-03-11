#include "thread_call.h"

#if __arm64__
#include "arm64/thread_call_arm64.h"
#elif __x86_64__
#include "x86_64/thread_call_x86_64.h"
#endif

#include "tx_log.h"

#include <assert.h>

const void *
thread_save_state(thread_act_t thread) {
	typedef const void *(*thread_save_state_fn)(thread_act_t);
	thread_save_state_fn impl = NULL;
#if __arm64__
	impl = thread_save_state_arm64;
#endif
	if (impl == NULL) {
		DEBUG_TRACE(1, "%s: No implementation available for this platform", __func__);
		return false;
	}
	return impl(thread);
}

bool
thread_restore_state(thread_act_t thread, const void *state) {
	typedef bool (*thread_restore_state_fn)(thread_act_t, const void *);
	thread_restore_state_fn impl = NULL;
#if __arm64__
	impl = thread_restore_state_arm64;
#endif
	if (impl == NULL) {
		DEBUG_TRACE(1, "%s: No implementation available for this platform", __func__);
		return false;
	}
	return impl(thread, state);
}

bool
thread_call(thread_act_t thread, void *result, size_t result_size,
		word_t function, unsigned argument_count, const word_t *arguments) {
	assert(result != NULL || function == 0 || result_size == 0);
	assert(result_size <= sizeof(word_t));
	assert(argument_count <= 8);
	typedef bool (*thread_call_fn)(thread_act_t, void *, size_t,
			word_t, unsigned, const word_t *);
	thread_call_fn impl = NULL;
#if __arm64__
	impl = thread_call_arm64;
#endif
	if (impl == NULL) {
		return false;
	}
	if (function != 0) {
		bool can_call = impl(thread, result, result_size, 0, argument_count, arguments);
		if (!can_call) {
			return false;
		}
	}
	return impl(thread, result, result_size, function, argument_count, arguments);
}

bool
thread_call_stack(thread_act_t thread,
		void *local_stack_base, word_t remote_stack_base, size_t stack_size,
		void *result, size_t result_size,
		word_t function, unsigned argument_count,
		const struct threadexec_call_argument *arguments) {
	assert(result != NULL || function == 0 || result_size == 0);
	assert(result_size <= sizeof(word_t));
	assert(argument_count <= 32);
	typedef bool (*thread_call_fn)(thread_act_t,
			void *, word_t, size_t,
			void *, size_t,
			word_t, unsigned,
			const struct threadexec_call_argument *);
	thread_call_fn impl = NULL;
#if __arm64__
	impl = thread_call_stack_arm64;
#elif __x86_64__
	impl = thread_call_stack_x86_64;
#endif
	if (impl == NULL) {
		DEBUG_TRACE(1, "%s: No implementation available for this platform", __func__);
		return false;
	}
	if (function != 0) {
		bool can_call = impl(thread,
				local_stack_base, remote_stack_base, stack_size,
				result, result_size,
				0, argument_count, arguments);
		if (!can_call) {
			DEBUG_TRACE(2, "Requested thread call is not supported");
			return false;
		}
	}
	DEBUG_TRACE(2, "Performing thread call of function %llx", function);
	return impl(thread,
			local_stack_base, remote_stack_base, stack_size,
			result, result_size,
			function, argument_count, arguments);
}
