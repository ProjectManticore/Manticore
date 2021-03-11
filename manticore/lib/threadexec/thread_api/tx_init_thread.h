#ifndef THREADEXEC__TX_INIT_THREAD_H_
#define THREADEXEC__TX_INIT_THREAD_H_

#include "tx_internal.h"

#if TX_HAVE_THREAD_API

/*
 * tx_init_with_thread_api
 *
 * Description:
 * 	Try to initialize the threadexec object using the Mach thread APIs rather than using the
 * 	Mach task APIs. This is primarily useful on iOS systems with security protections enabled.
 */
bool tx_init_with_thread_api(threadexec_t threadexec);

/*
 * tx_deinit_with_thread_api
 *
 * Description:
 * 	Try to deinitialize a threadexec object successfully initialized using
 * 	tx_init_with_thread_api.
 */
void tx_deinit_with_thread_api(threadexec_t threadexec);

#endif

#endif
