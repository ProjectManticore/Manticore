#include "thread_call_arm64.h"

#include "tx_log.h"
#include "tx_utils.h"

#include <assert.h>
#include <stdlib.h>
#include <mach/thread_status.h>

// Missing definitions.
typedef _STRUCT_ARM_CPMU_STATE64 arm_cpmu_state64_t;
#define ARM_CPMU_STATE64_COUNT ((mach_msg_type_number_t) \
   (sizeof (arm_cpmu_state64_t)/sizeof(uint32_t)))

static bool
thread_get_state_arm64(mach_port_t thread, arm_thread_state64_t *state) {
	mach_msg_type_number_t thread_state_count = ARM_THREAD_STATE64_COUNT;
	kern_return_t kr = thread_get_state(thread, ARM_THREAD_STATE64,
			(thread_state_t) state, &thread_state_count);
	return (kr == KERN_SUCCESS);
}

static bool
thread_set_state_arm64(mach_port_t thread, arm_thread_state64_t *state) {
	kern_return_t kr = thread_set_state(thread, ARM_THREAD_STATE64,
			(thread_state_t) state, ARM_THREAD_STATE64_COUNT);
	return (kr == KERN_SUCCESS);
}

// A structure representing the full state of a thread.
struct arm64_thread_state {
	arm_thread_state64_t    thread;
	arm_exception_state64_t exception;
	arm_neon_state64_t      neon;
	arm_debug_state64_t     debug;
	arm_cpmu_state64_t      cpmu;
	uint32_t                thread_valid:1,
	                        exception_valid:1,
	                        neon_valid:1,
	                        debug_valid:1,
	                        cpmu_valid:1;
};

const void *
thread_save_state_arm64(thread_act_t thread) {
	// We need to preserve more than just the integer state.
	struct arm64_thread_state *s = malloc(sizeof(*s));
	assert(s != NULL);
	mach_msg_type_number_t count;
	kern_return_t kr;
	// ARM_THREAD_STATE64
	count = ARM_THREAD_STATE64_COUNT;
	kr = thread_get_state(thread, ARM_THREAD_STATE64, (thread_state_t) &s->thread, &count);
	s->thread_valid = (kr == KERN_SUCCESS);
	if (kr != KERN_SUCCESS) {
		ERROR("%s: Failed to save %s state: %u", __func__, "ARM_THREAD_STATE64", kr);
		goto fail;
	}
	// ARM_EXCEPTION_STATE64
	count = ARM_EXCEPTION_STATE64_COUNT;
	kr = thread_get_state(thread, ARM_EXCEPTION_STATE64,
			(thread_state_t) &s->exception, &count);
	s->exception_valid = (kr == KERN_SUCCESS);
	if (kr != KERN_SUCCESS) {
		WARNING("%s: Failed to save %s state: %u", __func__, "ARM_EXCEPTION_STATE64", kr);
	}
	// ARM_NEON_STATE64
	count = ARM_NEON_STATE64_COUNT;
	kr = thread_get_state(thread, ARM_NEON_STATE64, (thread_state_t) &s->neon, &count);
	s->neon_valid = (kr == KERN_SUCCESS);
	if (kr != KERN_SUCCESS) {
		WARNING("%s: Failed to save %s state: %u", __func__, "ARM_NEON_STATE64", kr);
	}
	// ARM_DEBUG_STATE64
	count = ARM_DEBUG_STATE64_COUNT;
	kr = thread_get_state(thread, ARM_DEBUG_STATE64, (thread_state_t) &s->debug, &count);
	s->debug_valid = (kr == KERN_SUCCESS);
	if (kr != KERN_SUCCESS) {
		WARNING("%s: Failed to save %s state: %u", __func__, "ARM_DEBUG_STATE64", kr);
	}
	// ARM_CPMU_STATE64
	count = ARM_CPMU_STATE64_COUNT;
	kr = thread_get_state(thread, ARM_CPMU_STATE64, (thread_state_t) &s->cpmu, &count);
	s->cpmu_valid = (kr == KERN_SUCCESS);
	if (kr != KERN_SUCCESS) {
		WARNING("%s: Failed to save %s state: %u", __func__, "ARM_CPMU_STATE64", kr);
	}
	// Finally, try to reinitialize the thread so that we can use it for function calls. The
	// only thing we need to do is skip the stack red zone, the 128-byte region just below the
	// stack pointer. We'll skip a little more than this just to be safe.
	const size_t STACK_SKIP = 0x800;
	s->thread.__sp -= STACK_SKIP;
	kr = thread_set_state(thread, ARM_THREAD_STATE64, (thread_state_t) &s->thread,
			ARM_THREAD_STATE64_COUNT);
	s->thread.__sp += STACK_SKIP;
	if (kr != KERN_SUCCESS) {
		ERROR("%s: Failed to set new %s state: %u", __func__, "ARM_THREAD_STATE64", kr);
fail:
		free(s);
		s = NULL;
	}
	return s;
}

bool
thread_restore_state_arm64(thread_act_t thread, const void *state) {
	struct arm64_thread_state *s = (void *) state;
	kern_return_t kr;
	bool success = true;
	// ARM_THREAD_STATE64
	if (s->thread_valid) {
		kr = thread_set_state(thread, ARM_THREAD_STATE64, (thread_state_t) &s->thread,
				ARM_THREAD_STATE64_COUNT);
		if (kr != KERN_SUCCESS) {
			ERROR("%s: Failed to restore %s state: %u", __func__,
					"ARM_THREAD_STATE64", kr);
			success = false;
		}
	}
	// ARM_EXCEPTION_STATE64
	if (s->exception_valid) {
		kr = thread_set_state(thread, ARM_EXCEPTION_STATE64,
				(thread_state_t) &s->exception, ARM_EXCEPTION_STATE64_COUNT);
		if (kr != KERN_SUCCESS) {
			ERROR("%s: Failed to restore %s state: %u", __func__,
					"ARM_EXCEPTION_STATE64", kr);
			success = false;
		}
	}
	// ARM_NEON_STATE64
	if (s->neon_valid) {
		kr = thread_set_state(thread, ARM_NEON_STATE64, (thread_state_t) &s->neon,
				ARM_NEON_STATE64_COUNT);
		if (kr != KERN_SUCCESS) {
			ERROR("%s: Failed to restore %s state: %u", __func__,
					"ARM_NEON_STATE64", kr);
			success = false;
		}
	}
	// ARM_DEBUG_STATE64
	if (s->debug_valid) {
		kr = thread_set_state(thread, ARM_DEBUG_STATE64, (thread_state_t) &s->debug,
				ARM_DEBUG_STATE64_COUNT);
		if (kr != KERN_SUCCESS) {
			ERROR("%s: Failed to restore %s state: %u", __func__,
					"ARM_DEBUG_STATE64", kr);
			success = false;
		}
	}
	// ARM_CPMU_STATE64
	if (s->cpmu_valid) {
		kr = thread_set_state(thread, ARM_CPMU_STATE64, (thread_state_t) &s->cpmu,
				ARM_CPMU_STATE64_COUNT);
		if (kr != KERN_SUCCESS) {
			ERROR("%s: Failed to restore %s state: %u", __func__,
					"ARM_CPMU_STATE64", kr);
			success = false;
		}
	}
	// Now free the struct.
	free(s);
	return success;
}

// Find the address of a 'blr x19' gadget in the dyld shared cache.
// HACK: This heuristic is terrible.
static uint64_t
find_blr_x19() {
	static uint64_t blr_x19 = 1;
	if (blr_x19 == 1) {
		uint32_t blr_x19_ins = 0xd63f0260;
		void *start = &malloc;
		size_t size = 0x4000 * 128;
		void *found = memmem(start, size, &blr_x19_ins, sizeof(blr_x19_ins));
		blr_x19 = (uint64_t) found;
	}
	return blr_x19;
}

// Some code common to both thread_call_arm64 routines.
static bool
set_state_run_thread_wait_and_stop_thread(const char *_func,
		thread_act_t thread, arm_thread_state64_t *state) {
	// We need a stop condition. We'll just have the thread infinite loop on a 'blr x19' gadget
	// once the function returns.
	// NOTE: We could also make the thread crash on completion and set ourselves up as the
	// exception handler, which would eliminate the need for the gadget, but this seems
	// simpler.
	uint64_t blr_x19 = find_blr_x19();
	state->__lr = blr_x19;
	state->__x[19] = blr_x19;
	// Set the new state in the thread.
	bool success = thread_set_state_arm64(thread, state);
	if (!success) {
		ERROR("%s: Failed to set thread state for thread %x", _func, thread);
		return false;
	}
	// Run the thread.
	success = thread_resume_check(thread);
	if (!success) {
		ERROR("%s: Failed to resume thread %x", _func, thread);
		return false;
	}
	// Wait until the thread is in the expected state.
	for (;;) {
		success = thread_get_state_arm64(thread, state);
		if (!success) {
			// Possibly the thread crashed.
			thread_suspend_check(thread);
			ERROR("%s: Failed to get thread state for thread %x", _func, thread);
			return false;
		}
		if (state->__pc == blr_x19 && state->__x[19] == blr_x19) {
			break;
		}
	}
	// Suspend the thread.
	success = thread_suspend_check(thread);
	if (!success) {
		WARNING("%s: Failed to suspend thread %x", _func, thread);
	}
	return true;
}

#define REGISTER_ARGUMENT_COUNT 8

bool
thread_call_arm64(thread_act_t thread, void *result, size_t result_size,
		word_t function, unsigned argument_count, const word_t *arguments) {
	DEBUG_TRACE(2, "thread_call_arm64(%x, %llx, %u)", thread, function, argument_count);
	// Get the blr x19 gadget we'll need for later.
	uint64_t blr_x19 = find_blr_x19();
	// This thread call implementation only supports passing arguments in the registers.
	bool arguments_ok = (argument_count <= REGISTER_ARGUMENT_COUNT);
	// If the caller is just asking for whether we can perform this call, tell them.
	if (function == 0) {
		return (blr_x19 != 0 && arguments_ok);
	}
	// Now make sure we have the gadget.
	if (blr_x19 == 0) {
		ERROR("%s: Could not locate 'blr x19' gadget!", __func__);
		return false;
	}
	// And now make sure the arguments will work.
	if (!arguments_ok) {
		ERROR("%s: Unsupported number of arguments: %zu", __func__, argument_count);
		return false;
	}
	// Get the initial state of the thread. We don't save the stack pointer because we assume
	// that the function will restore the original stack pointer.
	arm_thread_state64_t state;
	bool success = thread_get_state_arm64(thread, &state);
	if (!success) {
		ERROR("%s: Failed to get thread state for thread %x", __func__, thread);
		return false;
	}
	// Set the values of the registers to execute our function call. We set registers x0
	// through x7 and pc to execute the function call then set x30 and x19 so that after the
	// function call the thread loops.
	for (unsigned i = 0; i < argument_count; i++) {
		state.__x[i] = arguments[i];
	}
	state.__pc = function;
	// Alright, now do the actual execution.
	success = set_state_run_thread_wait_and_stop_thread(__func__, thread, &state);
	if (!success) {
		return false;
	}
	// OK, everything looks good! Let's store the result.
	if (result_size > 0) {
		pack_uint(result, state.__x[0], result_size);
	}
	return true;
}

// Try to lay out the arguments on the stack and in registers.
//
// We assume for now that all arguments are integral.
//
// The first 8 arguments go into registers x0 through x7.
//
// Arguments after those get laid out onto the stack. Unlike the generic proceedure call standard,
// values on the stack do NOT consume space in multiples of 8 bytes. Instead, they consume only the
// space they need, although padding is still inserted to ensure that values are properly aligned.
//
// References:
//   - https://developer.apple.com/library/content/documentation/Xcode/Conceptual/iPhoneOSABIReference/Articles/ARM64FunctionCallingConventions.html
static bool
lay_out_arguments(uint64_t *registers, void *stack, size_t stack_size,
		unsigned argument_count, const struct threadexec_call_argument *arguments) {
	size_t i = 0;
	// Register arguments go directly in registers; no translation needed.
	for (; i < argument_count && i < REGISTER_ARGUMENT_COUNT; i++) {
		registers[i] = arguments[i].value;
	}
	// Stack arguments get packed and aligned.
	size_t stack_position = 0;
	for (; i < argument_count; i++) {
		// Insert any padding we need.
		size_t alignment = lobit(arguments[i].size | 0x8);
		assert(arguments[i].size == alignment);
		stack_position = round2_up(stack_position, alignment);
		// Check that the argument fits in the available stack space.
		size_t next_position = stack_position + arguments[i].size;
		if (next_position > stack_size) {
			return false;
		}
		// Add the argument to the stack.
		pack_uint((uint8_t *)stack + stack_position, arguments[i].value,
				arguments[i].size);
		next_position = stack_position;
	}
	return (i == argument_count);
}

bool
thread_call_stack_arm64(thread_act_t thread,
		void *local_stack_base, word_t remote_stack_base, size_t stack_size,
		void *result, size_t result_size,
		word_t function, unsigned argument_count,
		const struct threadexec_call_argument *arguments) {
	// Get the blr x19 gadget we'll need for later.
	uint64_t blr_x19 = find_blr_x19();
	// Process the arguments and lay out the stack.
	uint64_t registers[REGISTER_ARGUMENT_COUNT];
	size_t stack_args_size = 32 * sizeof(word_t);
	void *stack = (uint8_t *)local_stack_base - stack_args_size;
	uint64_t remote_stack = remote_stack_base - stack_args_size;
	bool args_ok = lay_out_arguments(registers, stack, stack_args_size,
			argument_count, arguments);
	// If the caller is just asking for whether we can perform this call, tell them.
	if (function == 0) {
		return (blr_x19 != 0 && args_ok);
	}
	// Now make sure we have the gadget.
	if (blr_x19 == 0) {
		ERROR("%s: Could not locate 'blr x19' gadget!", __func__);
		return false;
	}
	// And now make sure the arguments will work.
	if (!args_ok) {
		ERROR("%s: Unsupported number of arguments: %zu", __func__, argument_count);
		return false;
	}
	// Set the values of the registers to execute our function call. We set registers x0
	// through x7 to the first 8 arguments, sp to the top of the remote stack containing the
	// remaining arguments, pc to the function to call, and x30 and x19 to the 'blr x19' gadget
	// so that the thread infinite loops when done.
	arm_thread_state64_t state = {};
	for (unsigned i = 0; i < sizeof(registers) / sizeof(*registers); i++) {
		state.__x[i] = registers[i];
	}
	state.__sp = remote_stack;
	state.__pc = function;
	// Alright, now do the actual execution.
	bool success = set_state_run_thread_wait_and_stop_thread(__func__, thread, &state);
	if (!success) {
		return false;
	}
	// OK, everything looks good! Let's store the result.
	if (result_size > 0) {
		pack_uint(result, state.__x[0], result_size);
	}
	return true;
}
