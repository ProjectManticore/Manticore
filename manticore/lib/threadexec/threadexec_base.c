#include "tx_internal.h"

#include <assert.h>

mach_port_t
threadexec_task(threadexec_t threadexec) {
	return threadexec->task;
}

mach_port_t
threadexec_task_remote(threadexec_t threadexec) {
	assert(threadexec->task == MACH_PORT_NULL || threadexec->task_remote != MACH_PORT_NULL);
	return threadexec->task_remote;
}

mach_port_t
threadexec_thread(threadexec_t threadexec) {
	return threadexec->thread;
}

mach_port_t
threadexec_thread_remote(threadexec_t threadexec) {
	assert(threadexec->thread == MACH_PORT_NULL || threadexec->thread_remote != MACH_PORT_NULL);
	return threadexec->thread_remote;
}
