#include "tx_stage0_read_write.h"

#if TX_HAVE_THREAD_API

#include "tx_call.h"
#include "tx_log.h"

#include <objc/runtime.h>

#if __LP64__

extern void _xpc_int64_set_value(void *xint, int64_t value);

static bool
tx_stage0_write_word_64(threadexec_t threadexec, word_t address, word_t value) {
	// In order to write a word of the remote thread's memory we will call the function
	// _xpc_int64_set_value(), which sets the value at offset 0x18 into the memory block.
	word_t arguments[2] = { address - 0x18, value };
	bool success = tx_call_regs(threadexec, NULL, 0,
			(word_t) _xpc_int64_set_value, 2, arguments);
	if (!success) {
		ERROR("%s: Could not write address %llx", __func__, address);
	}
	return success;
}

#else // __LP64__

static bool
tx_stage0_write_word_32(threadexec_t threadexec, word_t address, word_t value) {
#error 32-bit tx_stage0_write_word not implemented.
	ERROR("%s: Not implemented", __func__);
	return false;
}

#endif // __LP64__

bool
tx_stage0_read_word(threadexec_t threadexec, word_t address, word_t *value) {
	// In order to read a word of the remote thread's memory we will call the function
	// property_getName(), declared in objc/runtime.h. This function retrieves the name field
	// of an objc_property_t object. The objc_property_t object is opaque, but the name field
	// is the first in the structure.
	word_t function = (word_t) property_getName;
	word_t arguments[1] = { address };
	bool success = tx_call_regs(threadexec, value, sizeof(*value),
			function, 1, arguments);
	if (!success) {
		ERROR("%s: Could not read address %llx", __func__, address);
	}
	return success;
}

bool
tx_stage0_write_word(threadexec_t threadexec, word_t address, word_t value) {
#if __LP64__
	return tx_stage0_write_word_64(threadexec, address, value);
#else
	return tx_stage0_write_word_32(threadexec, address, value);
#endif
}

bool
tx_stage0_read(threadexec_t threadexec, word_t address, void *value, size_t size) {
	word_t *word = value;
	size_t count = size / sizeof(*word);
	if (count * sizeof(*word) != size) {
		ERROR("%s: size %zu is not a multiple of the word size %zu", size, sizeof(*word));
		return false;
	}
	for (size_t i = 0; i < count; i++) {
		bool success = tx_stage0_read_word(threadexec, address, word);
		if (!success) {
			return false;
		}
		address += sizeof(*word);
		word    += 1;
	}
	return true;
}

bool
tx_stage0_write(threadexec_t threadexec, word_t address, const void *value, size_t size) {
	const word_t *word = value;
	size_t count = size / sizeof(*word);
	if (count * sizeof(*word) != size) {
		ERROR("%s: size %zu is not a multiple of the word size %zu", size, sizeof(*word));
		return false;
	}
	for (size_t i = 0; i < count; i++) {
		bool success = tx_stage0_write_word(threadexec, address, *word);
		if (!success) {
			return false;
		}
		address += sizeof(*word);
		word    += 1;
	}
	return true;
}

#endif // TX_HAVE_THREAD_API
