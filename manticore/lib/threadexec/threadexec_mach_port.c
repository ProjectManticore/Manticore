#include "tx_internal.h"

#include "tx_log.h"

#define PORT_TRANSFER_MSG_ID 0x139a717

// A Mach message struct for transferring a port.
struct port_transfer_msg {
	mach_msg_header_t          hdr;
	mach_msg_body_t            body;
	mach_msg_port_descriptor_t port;
};

struct port_transfer_msg_trailer {
	mach_msg_header_t          hdr;
	mach_msg_body_t            body;
	mach_msg_port_descriptor_t port;
	mach_msg_trailer_t         trailer;
};

bool
threadexec_mach_port_deallocate(threadexec_t threadexec,
		mach_port_t remote_port_name) {
	bool ok = threadexec_call_cv(threadexec, NULL, 0,
			mach_port_deallocate, 2,
			TX_CARG_LITERAL(mach_port_t, threadexec->task_remote),
			TX_CARG_LITERAL(mach_port_t, remote_port_name));
	if (!ok) {
		ERROR_REMOTE_CALL(mach_port_deallocate);
	}
	return ok;
}

// Extract a Mach port from the remote task using the task API.
static bool
extract_with_task_api(threadexec_t threadexec,
		mach_port_name_t remote_port_name, mach_port_t *local_port,
		mach_msg_type_name_t disposition) {
	mach_port_t extracted_right;
	mach_msg_type_name_t acquired_type;
	kern_return_t kr = mach_port_extract_right(threadexec->task, remote_port_name,
			disposition, &extracted_right, &acquired_type);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(mach_port_extract_right, "%u", kr);
		return false;
	}
	// TODO: Check that the right type is correct.
	*local_port = extracted_right;
	return true;
}

#if TX_HAVE_THREAD_API

// Extract a Mach port from the remote task using the task API.
static bool
extract_with_thread_api(threadexec_t threadexec,
		mach_port_name_t remote_port_name, mach_port_t *local_port,
		mach_msg_type_name_t disposition) {
	bool success = false;
	// Send a Mach message containing the right that we will receive from the remote thread.
	mach_msg_id_t msg_id = PORT_TRANSFER_MSG_ID + remote_port_name;
	struct port_transfer_msg *msg = (struct port_transfer_msg *) threadexec->shmem;
	memset(msg, 0, sizeof(*msg));
	msg->hdr.msgh_bits              = MACH_MSGH_BITS_SET(MACH_MSG_TYPE_COPY_SEND, 0,
	                                                     0, MACH_MSGH_BITS_COMPLEX);
	msg->hdr.msgh_size              = sizeof(*msg);
	msg->hdr.msgh_remote_port       = threadexec->local_port_remote;
	msg->hdr.msgh_id                = msg_id;
	msg->body.msgh_descriptor_count = 1;
	msg->port.name                  = remote_port_name;
	msg->port.disposition           = disposition;
	msg->port.type                  = MACH_MSG_PORT_DESCRIPTOR;
	struct threadexec_call_argument send_args[7] = {
		TX_ARG(mach_msg_header_t *, threadexec->shmem_remote),
		TX_ARG(mach_msg_option_t,   MACH_SEND_MSG),
		TX_ARG(mach_msg_size_t,     sizeof(*msg)),
		TX_ARG(mach_msg_size_t,     0),
		TX_ARG(mach_port_t,         MACH_PORT_NULL),
		TX_ARG(mach_msg_timeout_t,  MACH_MSG_TIMEOUT_NONE),
		TX_ARG(mach_port_t,         MACH_PORT_NULL),
	};
	DEBUG_TRACE(3, "Calling mach_msg() in remote thread to send port 0x%x", remote_port_name);
	kern_return_t kr;
	bool ok = threadexec_call(threadexec, &kr, sizeof(kr), mach_msg, 7, send_args);
	if (!ok) {
		ERROR_REMOTE_CALL(mach_msg);
		goto fail_0;
	}
	if (kr != KERN_SUCCESS) {
		ERROR_REMOTE_CALL_FAIL(mach_msg, "%u", kr);
		goto fail_0;
	}
	// Receive the Mach message in the local thread.
	DEBUG_TRACE(3, "Calling mach_msg() in local thread to receive the port");
	struct port_transfer_msg_trailer msg_local;
	kr = mach_msg(&msg_local.hdr,
			MACH_RCV_MSG,
			0,
			sizeof(msg_local),
			threadexec->local_port,
			MACH_MSG_TIMEOUT_NONE,
			MACH_PORT_NULL);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(mach_msg, "%u", kr);
		goto fail_0;
	}
	// TODO: It's entirely possible another message is received on the port first.
	if (msg_local.hdr.msgh_id != msg_id) {
		ERROR("Received unexpected message ID %x on %s Mach port",
				"local", msg_local.hdr.msgh_id);
		goto fail_0;
	}
	// Success!
	DEBUG_TRACE(3, "Got local port 0x%x", msg_local.port.name);
	*local_port = msg_local.port.name;
	success = true;
fail_0:
	return success;
}

#endif // TX_HAVE_THREAD_API

bool
threadexec_mach_port_extract(threadexec_t threadexec,
		mach_port_name_t remote_port_name, mach_port_t *local_port,
		mach_msg_type_name_t disposition) {
	bool ok;
	if (tx_supports_task_api(threadexec)) {
		ok = extract_with_task_api(threadexec, remote_port_name, local_port, disposition);
		if (ok) {
			return ok;
		}
	}
#if TX_HAVE_THREAD_API
	ok = extract_with_thread_api(threadexec, remote_port_name, local_port, disposition);
	if (ok) {
		return true;
	}
#endif
	return false;
}

bool
threadexec_mach_port_insert(threadexec_t threadexec,
		mach_port_t local_port, mach_port_name_t *remote_port_name,
		mach_msg_type_name_t disposition) {
	bool success = false;
	// Send a Mach message that the remote thread will receive containing the right.
	mach_msg_id_t msg_id = PORT_TRANSFER_MSG_ID + local_port;
	struct port_transfer_msg msg = {};
	msg.hdr.msgh_bits              = MACH_MSGH_BITS_SET(MACH_MSG_TYPE_COPY_SEND, 0,
	                                                    0, MACH_MSGH_BITS_COMPLEX);
	msg.hdr.msgh_size              = sizeof(msg);
	msg.hdr.msgh_remote_port       = threadexec->remote_port;
	msg.hdr.msgh_id                = msg_id;
	msg.body.msgh_descriptor_count = 1;
	msg.port.name                  = local_port;
	msg.port.disposition           = disposition;
	msg.port.type                  = MACH_MSG_PORT_DESCRIPTOR;
	kern_return_t kr = mach_msg(&msg.hdr,
			MACH_SEND_MSG,
			msg.hdr.msgh_size,
			0,
			MACH_PORT_NULL,
			MACH_MSG_TIMEOUT_NONE,
			MACH_PORT_NULL);
	if (kr != KERN_SUCCESS) {
		ERROR_CALL(mach_msg, "%u", kr);
		goto fail_0;
	}
	// Receive the Mach message in the remote thread.
	word_t remote_msg = threadexec->shmem_remote;
	struct port_transfer_msg *remote_msg_local = (struct port_transfer_msg *)threadexec->shmem;
	struct threadexec_call_argument recv_args[7] = {
		TX_ARG(mach_msg_header_t *, remote_msg),
		TX_ARG(mach_msg_option_t,   MACH_RCV_MSG),
		TX_ARG(mach_msg_size_t,     0),
		TX_ARG(mach_msg_size_t,     sizeof(struct port_transfer_msg_trailer)),
		TX_ARG(mach_port_t,         threadexec->remote_port_remote),
		TX_ARG(mach_msg_timeout_t,  MACH_MSG_TIMEOUT_NONE),
		TX_ARG(mach_port_t,         MACH_PORT_NULL),
	};
	bool ok = threadexec_call(threadexec, &kr, sizeof(kr), mach_msg, 7, recv_args);
	if (!ok) {
		ERROR_REMOTE_CALL(mach_msg);
		goto fail_0;
	}
	if (kr != KERN_SUCCESS) {
		ERROR_REMOTE_CALL_FAIL(mach_msg, "%u", kr);
		goto fail_0;
	}
	// TODO: It's entirely possible another message is received on the port first.
	if (remote_msg_local->hdr.msgh_id != msg_id) {
		ERROR("Received unexpected message ID %x on %s Mach port",
				"remote", remote_msg_local->hdr.msgh_id);
		goto fail_0;
	}
	// Success!
	*remote_port_name = remote_msg_local->port.name;
	success = true;
fail_0:
	return success;
}
