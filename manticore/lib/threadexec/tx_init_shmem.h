#ifndef THREADEXEC__TX_INIT_SHMEM_H_
#define THREADEXEC__TX_INIT_SHMEM_H_

#include "threadexec/threadexec.h"

/*
 * tx_init_shmem_setup_regions
 *
 * Description:
 * 	Set up the stack and client regions from the initial shared memory region.
 */
void tx_init_shmem_setup_regions(threadexec_t threadexec);

#endif
