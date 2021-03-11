#ifndef THREADEXEC__TX_LOG_H_
#define THREADEXEC__TX_LOG_H_

#include "threadexec/threadexec.h"

#define DEBUG_LEVEL(level)	(DEBUG && level <= DEBUG)

#if DEBUG
#define DEBUG_TRACE(level, fmt, ...)						\
	do {									\
		if (DEBUG_LEVEL(level)) {					\
			tx_log_internal('D', fmt, ##__VA_ARGS__);		\
		}								\
	} while (0)
#else
#define DEBUG_TRACE(level, fmt, ...)	do {} while (0)
#endif
#define INFO(fmt, ...)			tx_log_internal('I', fmt, ##__VA_ARGS__)
#define WARNING(fmt, ...)		tx_log_internal('W', fmt, ##__VA_ARGS__)
#define ERROR(fmt, ...)			tx_log_internal('E', fmt, ##__VA_ARGS__)

#define ERROR_CALL(fn, fmt, ret)	\
	ERROR("%s: "fmt, #fn, ret)

#define ERROR_REMOTE_CALL(fn)	\
	ERROR("Could not call %s in remote thread", #fn)

#define ERROR_REMOTE_CALL_FAIL(fn, fmt, ret)	\
	ERROR("Remote call to %s returned "fmt, #fn, ret)

// A function to call the logging implementation.
void tx_log_internal(char type, const char *format, ...);

#endif
