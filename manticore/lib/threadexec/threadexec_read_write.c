#include "tx_internal.h"

#include "tx_log.h"
#include "tx_utils.h"

// If we had a usable task port we'd use that, but sadly we just have memcpy.

// Transfer data from the local buffer to the remote address or vice versa. Currently data is
// transferred in 16K chunks, with no special treatment for especially large buffers.
static bool
transfer(threadexec_t threadexec, word_t remote_address, void *data, size_t size, bool is_write) {
	void *shmem_local = threadexec->shmem;
	word_t shmem_remote = threadexec->shmem_remote;
	while (size > 0) {
		size_t transfer_size = min(size, 0x4000);
		if (is_write) {
			memcpy(shmem_local, data, transfer_size);
		}
		struct threadexec_call_argument memcpy_args[3] = {
			TX_ARG(void *,       (is_write ? remote_address : shmem_remote)),
			TX_ARG(const void *, (is_write ? shmem_remote   : remote_address)),
			TX_ARG(size_t,       transfer_size),
		};
		bool ok = threadexec_call(threadexec, NULL, 0, memcpy, 3, memcpy_args);
		if (!ok) {
			ERROR("Memory transfer failed with %zu bytes left", size);
			break;
		}
		if (!is_write) {
			memcpy(data, shmem_local, transfer_size);
		}
		size           -= transfer_size;
		data            = (uint8_t *)data + transfer_size;
		remote_address += transfer_size;
	}
	return (size == 0);
}

bool
threadexec_read(threadexec_t threadexec, const void *remote_address, void *data, size_t size) {
	return transfer(threadexec, (word_t) remote_address, data, size, false);
}

bool
threadexec_write(threadexec_t threadexec, const void *remote_address,
		const void *data, size_t size) {
	return transfer(threadexec, (word_t) remote_address, (void *) data, size, true);
}
