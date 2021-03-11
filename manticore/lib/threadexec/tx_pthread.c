#include "tx_pthread.h"

#include "tx_call.h"
#include "tx_internal.h"
#include "tx_log.h"

#include <pthread.h>

// _pthread_set_self() initializes thread-local storage.
extern void _pthread_set_self(pthread_t);

bool
tx_pthread_init_bare_thread(threadexec_t threadexec) {
	bool success = false;
	// Set our pthread context to the main thread's pthread context. This will allow us to use
	// thread-local storage.
	//
	// We may enter this point with one of two separate levels of initialization: we may have
	// shared memory but no stack pointer (task API), or we may have a stack pointer but no
	// shared memory (thread API). In the first case we use tx_call() to initialize the stack
	// pointer register, while in the latter we use tx_call_regs() to leave the stack pointer
	// register alone.
	bool ok;
	if (threadexec->shmem != NULL) {
		struct threadexec_call_argument _pthread_set_self_args[1] = {
			TX_ARG(pthread_t, NULL),
		};
		ok = tx_call(threadexec, NULL, 0,
				(word_t) _pthread_set_self, 1, _pthread_set_self_args);
	} else {
		word_t _pthread_set_self_args[1] = {
			(word_t) (pthread_t) NULL,
		};
		ok = tx_call_regs(threadexec, NULL, 0,
				(word_t) _pthread_set_self, 1, _pthread_set_self_args);
	}
	if (!ok) {
		ERROR_REMOTE_CALL(_pthread_set_self);
		goto fail_0;
	}
	// TODO: Create a new pthread context and switch to that!
	success = true;
fail_0:
	return success;
}
