#ifndef THREADEXEC__TX_UTILS_H_
#define THREADEXEC__TX_UTILS_H_

#include "threadexec/threadexec.h"

/*
 * thread_suspend_check
 *
 * Description:
 * 	Suspend execution of the specified Mach thread.
 */
bool thread_suspend_check(thread_act_t thread);

/*
 * thread_resume_check
 *
 * Description:
 * 	Resume execution of the specified Mach thread.
 */
bool thread_resume_check(thread_act_t thread);

/*
 * thread_abort_check
 *
 * Description:
 * 	Abort the kernel execution of the specified Mach thread.
 */
bool thread_abort_check(thread_act_t thread);

/*
 * thread_suspend_and_abort_check
 *
 * Description:
 * 	Suspend and abort the thread. Used during initialization to coopt an existing running
 * 	thread.
 */
bool thread_suspend_and_abort_check(thread_act_t thread);

/*
 * thread_get_suspend_count
 *
 * Description:
 * 	Get the current user suspend count for the thread.
 */
int thread_get_suspend_count(thread_inspect_t thread);

/*
 * thread_get_run_state
 *
 * Description:
 * 	Get the run state of the thread.
 */
int thread_get_run_state(thread_inspect_t thread);

/*
 * mach_port_allocate_receive_and_send
 *
 * Description:
 * 	Create a new receive right with a single send right.
 */
mach_port_t mach_port_allocate_receive_and_send();

/*
 * macro min
 *
 * Description:
 * 	Find the minimum of two values.
 */
#define min(a, b)								\
	({ __typeof__(a) _min_a = (a);						\
	   __typeof__(b) _min_b = (b);						\
	   (_min_a < _min_b ? _min_a : _min_b); })


/*
 * pack_uint
 *
 * Description:
 * 	Store an integer into a memory location with the specified size.
 */
static inline void
pack_uint(void *dest, uintmax_t value, size_t width) {
	switch (width) {
		case 1: *(uint8_t  *)dest = (uint8_t)  value; break;
		case 2: *(uint16_t *)dest = (uint16_t) value; break;
		case 4: *(uint32_t *)dest = (uint32_t) value; break;
#ifdef UINT64_MAX
		case 8: *(uint64_t *)dest = (uint64_t) value; break;
#endif
	}
}

/*
 * lobit
 *
 * Description:
 * 	Returns a mask of the least significant 1 bit.
 */
static inline uintmax_t
lobit(uintmax_t x) {
	return (x & (-x));
}

/*
 * macro round2_down
 *
 * Description:
 * 	Round a down to the nearest multiple of b, which must be a power of 2.
 */
#define round2_down(a, b)		((a) & ~((b) - 1))

/*
 * macro round2_up
 *
 * Description:
 * 	Round a up to the nearest multiple of b, which must be a power of 2.
 */
#define round2_up(a, b)								\
	({ __typeof__(a) _round2_up_a = (a);					\
	   __typeof__(b) _round2_up_b = (b);					\
	   round2_down(_round2_up_a + _round2_up_b - 1, _round2_up_b); })

#endif
