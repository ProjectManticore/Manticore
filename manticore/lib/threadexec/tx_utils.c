#include "tx_utils.h"

#include "tx_log.h"

bool
thread_suspend_check(thread_act_t thread) {
	DEBUG_TRACE(3, "thread_suspend(0x%x)", thread);
	kern_return_t kr = thread_suspend(thread);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(thread_suspend, "%u", kr);
	}
	return (kr == KERN_SUCCESS);
}

bool
thread_resume_check(thread_act_t thread) {
	DEBUG_TRACE(3, "thread_resume(0x%x)", thread);
	kern_return_t kr = thread_resume(thread);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(thread_resume, "%u", kr);
	}
	return (kr == KERN_SUCCESS);
}

bool
thread_abort_check(thread_act_t thread) {
	DEBUG_TRACE(3, "thread_abort(0x%x)", thread);
	kern_return_t kr = thread_abort(thread);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(thread_abort, "%u", kr);
	}
	return (kr == KERN_SUCCESS);
}

bool
thread_suspend_and_abort_check(thread_act_t thread) {
	bool ok = thread_suspend_check(thread);
	if (!ok) {
		ERROR("Could not suspend thread 0x%x", thread);
		return false;
	}
	ok = thread_abort_check(thread);
	if (!ok) {
		WARNING("Could not abort thread 0x%x", thread);
	}
	return true;
}

static bool
thread_basic_info(thread_inspect_t thread, thread_basic_info_t info) {
	mach_msg_type_number_t count = THREAD_BASIC_INFO_COUNT;
	kern_return_t kr = thread_info(thread, THREAD_BASIC_INFO, (thread_info_t) info, &count);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(thread_info, "%u", kr);
		return false;
	}
	return true;
}

int
thread_get_suspend_count(thread_inspect_t thread) {
	thread_basic_info_data_t info;
	bool ok = thread_basic_info(thread, &info);
	if (!ok) {
		return -1;
	}
	return info.suspend_count;
}

int
thread_get_run_state(thread_inspect_t thread) {
	thread_basic_info_data_t info;
	bool ok = thread_basic_info(thread, &info);
	if (!ok) {
		return -1;
	}
	return info.run_state;
}

mach_port_t
mach_port_allocate_receive_and_send() {
	mach_port_t port;
	kern_return_t kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &port);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(mach_port_allocate, "%u", kr);
		return MACH_PORT_NULL;
	}
	kr = mach_port_insert_right(mach_task_self(), port, port, MACH_MSG_TYPE_MAKE_SEND);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(mach_port_insert_right, "%u", kr);
		mach_port_deallocate(mach_task_self(), port);
		return MACH_PORT_NULL;
	}
	return port;
}
