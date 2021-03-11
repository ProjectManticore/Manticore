#ifndef THREADEXEC__TX_PTHREAD_H_
#define THREADEXEC__TX_PTHREAD_H_

#include "threadexec/threadexec.h"

/*
 * tx_pthread_init_bare_thread
 *
 * Description:
 * 	Set up the pthread context for a bare thread. The threadexec only needs to support
 * 	register-based calling.
 */
bool tx_pthread_init_bare_thread(threadexec_t threadexec);

#endif
