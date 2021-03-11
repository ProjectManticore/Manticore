#include "tx_log.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

// Log all messages to stderr.
static void
tx_log_stderr(char type, const char *format, va_list ap) {
	char *message = NULL;
	vasprintf(&message, format, ap);
	assert(message != NULL);
	const char *logtype   = "";
	const char *separator = ": ";
	switch (type) {
		case 'D': logtype = "Debug";   break;
		case 'I': logtype = "Info";    break;
		case 'W': logtype = "Warning"; break;
		case 'E': logtype = "Error";   break;
		default:  separator = "";
	}
	fprintf(stderr, "%s%s%s\n", logtype, separator, message);
	free(message);
}

void (*threadexec_log)(char type, const char *format, va_list ap) = tx_log_stderr;

void
tx_log_internal(char type, const char *format, ...) {
	if (threadexec_log != NULL) {
		va_list ap;
		va_start(ap, format);
		threadexec_log(type, format, ap);
		va_end(ap);
	}
}
