#ifndef THREADEXEC__TX_STAGE0_MACH_PORTS_H_
#define THREADEXEC__TX_STAGE0_MACH_PORTS_H_

#include "tx_internal.h"

#if TX_HAVE_THREAD_API

/*
 * tx_stage0_init_mach_ports
 *
 * Description:
 * 	Set up the Mach ports used by subsequent stages of threadexec. After this operation, the
 * 	threadexec is in stage 1 of initialization.
 *
 * Parameters:
 * 	threadexec			The threadexec context. Only the thread port needs to be
 * 					set up.
 *
 * Returns:
 * 	Returns true on success.
 */
bool tx_stage0_init_mach_ports(threadexec_t threadexec);

/*
 * tx_stage1_mach_port_insert_send
 *
 * Description:
 * 	Copy the send right for a Mach port into the remote thread. See
 * 	threadexec_mach_port_insert.
 */
bool tx_stage1_mach_port_insert_send(threadexec_t threadexec,
		mach_port_t local_port, mach_port_name_t *remote_port_name);

#endif

#endif
