#include "tx_call.h"

#include "thread_call.h"
#include "tx_internal.h"
#include "tx_log.h"

#include <assert.h>

bool
tx_preserve(threadexec_t threadexec) {
	assert(threadexec->preserve_state == NULL && threadexec->thread != MACH_PORT_NULL);
	const void *state = thread_save_state(threadexec->thread);
	if (state == NULL) {
		ERROR("Could not preserve thread 0x%x", threadexec->thread);
		return false;
	}
	threadexec->preserve_state = state;
	return true;
}

bool
tx_preserve_restore(threadexec_t threadexec) {
	DEBUG_TRACE(2, "Restoring preserved thread 0x%x", threadexec->thread);
	assert(threadexec->preserve_state != NULL && threadexec->thread != MACH_PORT_NULL);
	bool ok = thread_restore_state(threadexec->thread, threadexec->preserve_state);
	if (!ok) {
		ERROR("Could not restore preserved thread 0x%x", threadexec->thread);
		return false;
	}
	threadexec->preserve_state = NULL;
	return true;
}

bool
tx_call_regs(threadexec_t threadexec, void *result, size_t result_size,
		word_t function, unsigned argument_count, const word_t *arguments) {
#if TX_HAVE_THREAD_API
	return thread_call(threadexec->thread, result, result_size,
			(word_t) function, argument_count, arguments);
#else
	// On systems without the thread_call() function, we must have the task API. Otherwise we
	// literally have no usable APIs and we shouldn't have gotten this far.
	assert(tx_supports_task_api(threadexec));
	assert(argument_count <= 32);
	struct threadexec_call_argument arguments_array[argument_count];
	for (size_t i = 0; i < argument_count; i++) {
		arguments_array[i].size  = sizeof(word_t);
		arguments_array[i].value = arguments[i];
	}
	return tx_call(threadexec, result, result_size,
			function, argument_count, arguments_array);
#endif
}

bool
tx_call(threadexec_t threadexec,
		void *result, size_t result_size,
		word_t function, unsigned argument_count,
		const struct threadexec_call_argument *arguments) {
	return thread_call_stack(threadexec->thread, threadexec->stack_base,
			threadexec->stack_base_remote, threadexec->stack_size,
			result, result_size,
			(word_t) function, argument_count, arguments);
}
