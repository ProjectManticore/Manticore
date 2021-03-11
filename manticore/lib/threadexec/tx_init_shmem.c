#include "tx_init_shmem.h"

#include "tx_internal.h"
#include "tx_log.h"
#include "tx_params.h"

#include <assert.h>

void
tx_init_shmem_setup_regions(threadexec_t threadexec) {
	DEBUG_TRACE(2, "Set up shared memory: local = %p, remote = %p, size = %zu",
			threadexec->shmem, (void *) threadexec->shmem_remote,
			threadexec->shmem_size);
	assert(threadexec->shmem_size > TX_CLIENT_SHMEM_SIZE);
	// Initialize the stack, which is the lower part of the shared memory region.
	const size_t stack_size  = threadexec->shmem_size - TX_CLIENT_SHMEM_SIZE;
	void *stack_base         = (uint8_t *)threadexec->shmem + stack_size;
	word_t stack_base_remote = threadexec->shmem_remote + stack_size;
	threadexec->stack_base        = stack_base;
	threadexec->stack_base_remote = stack_base_remote;
	threadexec->stack_size        = stack_size;
	// Initialize the client shared memory region, which is the upper part.
	const size_t client_shmem_size = threadexec->shmem_size - stack_size;
	assert(client_shmem_size >= 0x8000);
	threadexec->client_shmem        = stack_base;
	threadexec->client_shmem_remote = stack_base_remote;
	threadexec->client_shmem_size   = client_shmem_size;
}
