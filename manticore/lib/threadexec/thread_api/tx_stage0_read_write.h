#ifndef THREADEXEC__TX_STAGE0_READ_WRITE_H_
#define THREADEXEC__TX_STAGE0_READ_WRITE_H_

#include "tx_internal.h"

#if TX_HAVE_THREAD_API

/*
 * tx_stage0_read_word
 *
 * Description:
 * 	Read a word from the remote thread's memory using only the thread port.
 *
 * Parameters:
 * 	threadexec			The threadexec context. Only the thread port needs to be
 * 					valid.
 * 	address				The remote memory address to read.
 * 	value			out	On return, the value of the word at that memory address.
 *
 * Returns:
 * 	Returns true on success.
 */
bool tx_stage0_read_word(threadexec_t threadexec, word_t address, word_t *value);

/*
 * tx_stage0_write_word
 *
 * Description:
 * 	Write a word to the remote thread's memory using only the thread port.
 *
 * Parameters:
 * 	threadexec			The threadexec context. Only the thread port needs to be
 * 					valid.
 * 	address				The remote memory address to write.
 * 	value				The word to write at that memory address.
 *
 * Returns:
 * 	Returns true on success.
 */
bool tx_stage0_write_word(threadexec_t threadexec, word_t address, word_t value);

/*
 * tx_stage0_read
 *
 * Description:
 * 	Read data from the remote thread's memory using only the thread port.
 *
 * Parameters:
 * 	threadexec			The threadexec context. Only the thread port needs to be
 * 					valid.
 * 	address				The remote memory address to read.
 * 	data			out	On return, contains the data at that memory address.
 * 	size				The number of bytes to read.
 *
 * Returns:
 * 	Returns true on success.
 */
bool tx_stage0_read(threadexec_t threadexec, word_t address, void *data, size_t size);

/*
 * tx_stage0_write
 *
 * Description:
 * 	Write data to the remote thread's memory using only the thread port.
 *
 * Parameters:
 * 	threadexec			The threadexec context. Only the thread port needs to be
 * 					valid.
 * 	address				The remote memory address to write.
 * 	data				The data to write at that memory address.
 * 	size				The number of bytes to write.
 *
 * Returns:
 * 	Returns true on success.
 */
bool tx_stage0_write(threadexec_t threadexec, word_t address,
		const void *data, size_t size);

#endif

#endif
