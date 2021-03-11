#include "tx_internal.h"

#include "tx_call.h"
#include "tx_log.h"

#include <assert.h>

bool
threadexec_call_fast(threadexec_t threadexec, void *result, size_t result_size,
		const void *function, unsigned argument_count, const word_t *arguments) {
	return tx_call_regs(threadexec, result, result_size,
			(word_t) function, argument_count, arguments);
}

bool
threadexec_call(threadexec_t threadexec, void *result, size_t result_size, const void *function,
		unsigned argument_count, const struct threadexec_call_argument *arguments) {
	return tx_call(threadexec, result, result_size,
			(word_t) function, argument_count, arguments);
}

bool
threadexec_call_c(threadexec_t threadexec, void *result, size_t result_size,
		const void *function, unsigned argument_count,
		const struct threadexec_call_c_argument *arguments) {
	bool success;
	assert(argument_count <= 32);
	struct threadexec_call_argument literal_arguments[32] = {};
	size_t shmem_size = 0;
	const uint8_t *shmem_remote;
	uint8_t *shmem_local;
	// Get the size of the shared memory region we'll need to establish.
	for (size_t i = 0; i < argument_count; i++) {
		switch (arguments[i].disposition) {
			case TX_DISPOSITION_PTR_DATA_IN:
			case TX_DISPOSITION_PTR_DATA_OUT:
			case TX_DISPOSITION_PTR_DATA_INOUT:
				shmem_size += arguments[i].data_size;
				break;
			default:
				break;
		}
	}
	// Set up the shared memory region. If it's smaller than 0x4000, just use the top of the
	// stack.
	if (shmem_size <= 0x4000) {
		shmem_remote = (const uint8_t *) threadexec->shmem_remote;
		shmem_local  = (uint8_t *) threadexec->shmem;
	} else {
		success = threadexec_shared_vm_allocate(threadexec, (const void **) &shmem_remote,
				(void **) &shmem_local, shmem_size);
		if (!success) {
			goto fail_0;
		}
	}
	// Preprocess the arguments to get the literal arguments.
	size_t shmem_position = 0;
	for (size_t i = 0; i < argument_count; i++) {
		enum threadexec_value_disposition disposition = arguments[i].disposition;
		switch (disposition) {
			case TX_DISPOSITION_LITERAL:
				literal_arguments[i].value = arguments[i].value;
				break;
			case TX_DISPOSITION_PTR_DATA_IN:
			case TX_DISPOSITION_PTR_DATA_OUT:
			case TX_DISPOSITION_PTR_DATA_INOUT:
				literal_arguments[i].value = (word_t)
					shmem_remote + shmem_position;
				if (disposition & TX_DISPOSITION_PTR_DATA_IN) {
					memcpy(shmem_local + shmem_position,
							(const void *)arguments[i].value,
							arguments[i].data_size);
				}
				shmem_position += arguments[i].data_size;
				break;
			default:
				assert(false);
		}
		literal_arguments[i].size = arguments[i].literal_size;
	}
	// Perform the function call on the literal arguments.
	success = threadexec_call(threadexec, result, result_size,
			function, argument_count, literal_arguments);
	if (!success) {
		goto fail_1;
	}
	// Post-process the arguments.
	shmem_position = 0;
	for (size_t i = 0; i < argument_count; i++) {
		enum threadexec_value_disposition disposition = arguments[i].disposition;
		switch (disposition) {
			case TX_DISPOSITION_PTR_DATA_IN:
			case TX_DISPOSITION_PTR_DATA_OUT:
			case TX_DISPOSITION_PTR_DATA_INOUT:
				if (disposition & TX_DISPOSITION_PTR_DATA_OUT) {
					memcpy((void *)arguments[i].value,
							shmem_local + shmem_position,
							arguments[i].data_size);
				}
				shmem_position += arguments[i].data_size;
				break;
			default:
				break;
		}
	}
fail_1:
	if (shmem_size > 0 && (word_t) shmem_remote != threadexec->shmem_remote) {
		threadexec_shared_vm_deallocate(threadexec, shmem_remote, shmem_local, shmem_size);
	}
fail_0:
	return success;
}

bool
threadexec_call_cv(threadexec_t threadexec, void *result, size_t result_size,
		const void *function, unsigned argument_count, ...) {
	assert(argument_count <= 32);
	// Collect all the arguments into an array.
	struct threadexec_call_c_argument argument_array[32];
	va_list ap;
	va_start(ap, argument_count);
	for (size_t i = 0; i < argument_count; i++) {
		argument_array[i] = va_arg(ap, struct threadexec_call_c_argument);
	}
	va_end(ap);
	// Do the regular function call.
	return threadexec_call_c(threadexec, result, result_size,
			function, argument_count, argument_array);
}
