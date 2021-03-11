#ifndef THREADEXEC__TX_INIT_TASK_H_
#define THREADEXEC__TX_INIT_TASK_H_

#include "threadexec/threadexec.h"

/*
 * tx_init_with_task_api
 *
 * Description:
 * 	Try to initialize the threadexec object using the Mach task APIs rather than using the Mach
 * 	thread APIs. This is primarily useful on macOS systems or on iOS systems with security
 * 	protections disabled.
 *
 * Notes:
 * 	If this doesn't work on macOS/x86-64, then we don't really have another option to
 * 	initialize.
 */
bool tx_init_with_task_api(threadexec_t threadexec);

/*
 * tx_deinit_with_task_api
 *
 * Description:
 * 	Try to deinitialize the threadexec object using the Mach thread APIs. The object may have
 * 	been initialized with either the thread or task APIs.
 *
 * Returns:
 * 	Returns true if deinitialization was successful. Deinitialization will always be successful
 * 	for threadexec objects created using the task APIs.
 */
bool tx_deinit_with_task_api(threadexec_t threadexec);

#endif
