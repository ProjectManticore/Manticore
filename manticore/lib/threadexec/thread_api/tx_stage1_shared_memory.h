#ifndef THREADEXEC__TX_STAGE1_SHARED_MEMORY_H_
#define THREADEXEC__TX_STAGE1_SHARED_MEMORY_H_

#include "tx_internal.h"

#if TX_HAVE_THREAD_API

/*
 * tx_stage1_init_shared_memory
 *
 * Description:
 * 	Set up the shared memory region used by subsequent stages of threadexec. After this
 * 	operation, the threadexec is in stage 2 of initialization.
 *
 * Parameters:
 * 	threadexec			The threadexec context. This must be in stage 1.
 *
 * Returns:
 * 	Returns true on success.
 */
bool tx_stage1_init_shared_memory(threadexec_t threadexec);

#endif

#endif
