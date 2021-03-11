#ifndef THREADEXEC__THREADEXEC_H_
#define THREADEXEC__THREADEXEC_H_

#include <fcntl.h>
#include <mach/mach.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>


#if __LP64__
#define __word_t uint64_t
#else
#define __word_t uint32_t
#endif

/*
 * word_t
 *
 * Description:
 * 	An integer the same size as the CPU register.
 */
typedef __word_t word_t;

/*
 * threadexec_t
 *
 * Description:
 * 	An opaque type holding context for the threadexec API.
 */
typedef struct threadexec *threadexec_t;

/*
 * threadexec_call_argument
 *
 * Description:
 * 	Information about an argument to a threadexec_call function.
 */
struct threadexec_call_argument {
	// The type of argument. Currently not used.
	uint16_t type;
	// The size of the argument in bytes.
	uint16_t size;
	// The argument value.
	word_t   value;
};

#define __TX_ASSERT_IS_INTEGER(type)					\
	_Static_assert((sizeof(type) == 1 || sizeof(type) == 2		\
	                || sizeof(type) == 4 || sizeof(type) == 8)	\
	               && sizeof(type) <= sizeof(word_t),		\
	               "Supplied type is not an integer type")

#define __TX_ASSERT_IS_POINTER(type)					\
	_Static_assert(sizeof(type) == sizeof(void *),			\
	               "Supplied type is not a pointer")

/*
 * macro TX_ARG
 *
 * Description:
 * 	A macro to simplify building argument lists to threadexec_call().
 *
 * Notes:
 * 	Only integer/pointer types are currently supported.
 *
 * 	It is actually important that the correct type is supplied to this macro. The value will be
 * 	cast to that type to perform any C-style sign extension or other transformations on the
 * 	value.
 */
#define TX_ARG(type, value)						\
	({ __TX_ASSERT_IS_INTEGER(type);				\
	   (struct threadexec_call_argument) { 0, (uint16_t) sizeof(type), (word_t) (type) value }; })

/*
 * enum threadexec_value_disposition
 *
 * Description:
 * 	Metainformation about a value passed to threadexec_call_c.
 */
enum threadexec_value_disposition {
	// Pass a literal value.
	TX_DISPOSITION_LITERAL = 0x0,
	// Copy the data in the local buffer to the remote thread and pass a pointer to the remote
	// copy to the function. The remote input data buffer is live only for the duration of the
	// remote function call.
	TX_DISPOSITION_PTR_DATA_IN = 0x1,
	// Pass a pointer to a remote output buffer of the specified size to the function and copy
	// the data back to the local output buffer when the function returns. The remote output
	// buffer is live only for the duration of the remote function call.
	TX_DISPOSITION_PTR_DATA_OUT = 0x2,
	// A combination of TX_DISPOSITION_DATA_IN and TX_DISPOSITION_PTR_DATA_OUT,
	// suitable for example when a function modifies a buffer in-place.
	TX_DISPOSITION_PTR_DATA_INOUT = 0x3,
};

/*
 * threadexec_call_c_argument
 *
 * Description:
 * 	Information about an argument to a threadexec_call_c function. Build values of this type
 * 	using the TX_CARG_* macros.
 */
struct threadexec_call_c_argument {
	size_t literal_size;
	word_t value;
	enum threadexec_value_disposition disposition;
	size_t data_size;
};

#define __TX_CARG(type, value, disposition, data_size)			\
	((struct threadexec_call_c_argument) { sizeof(type), (word_t) value, disposition, data_size })

#define TX_CARG_LITERAL(type, value)					\
	__TX_CARG(type, value, TX_DISPOSITION_LITERAL, 0)

#define TX_CARG_PTR_DATA_IN(type, local_data, size)			\
	({ __TX_ASSERT_IS_POINTER(type);				\
	   __TX_CARG(type, local_data, TX_DISPOSITION_PTR_DATA_IN, size); })

#define TX_CARG_PTR_DATA_OUT(type, local_data, size)			\
	({ __TX_ASSERT_IS_POINTER(type);				\
	   __TX_CARG(type, local_data, TX_DISPOSITION_PTR_DATA_OUT, size); })

#define TX_CARG_PTR_DATA_INOUT(type, local_data, size)			\
	({ __TX_ASSERT_IS_POINTER(type);				\
	   __TX_CARG(type, local_data, TX_DISPOSITION_PTR_DATA_INOUT, size); })

#define TX_CARG_PTR_LITERAL_OUT(type, local_ptr_literal_out)		\
	TX_CARG_PTR_DATA_OUT(type, local_ptr_literal_out, sizeof(*((type)NULL)))

#define TX_CARG_PTR_LITERAL_INOUT(type, local_ptr_literal)		\
	TX_CARG_PTR_DATA_INOUT(type, local_ptr_literal, sizeof(*((type)NULL)))

#define TX_CARG_CSTRING(type, local_cstring)				\
	({ const char *_local_cstring = (local_cstring);		\
	   TX_CARG_PTR_DATA_IN(type, _local_cstring, strlen(_local_cstring) + 1); })

// The threadexec_init() creation flags.
enum {
	// Have threadexec_init() suspend all other threads in the task. These threads are not
	// automatically resumed.
	TX_SUSPEND_THREADS    = 0x1,
	// Kill the target thread when threadexec_deinit() is called. The state of the target
	// thread is not preserved.
	TX_KILL_THREAD        = 0x2,
	// Kill the target task when threadexec_deinit() is called. This implies TX_KILL_THREAD.
	TX_KILL_TASK          = 0x4,
	// The supplied thread is not suspended, so have threadexec_init() suspend (and abort) the
	// target thread.
	TX_SUSPEND            = 0x8,
	// Resume the thread after it has been restored in threadexec_deinit(). This option is
	// mutually exclusive with TX_KILL_THREAD.
	TX_RESUME             = 0x10,
	// The thread port is borrowed, not owned by the threadexec object. The port reference
	// count is not changed, so the client is responsible for managing the lifetime of the
	// thread port.
	TX_BORROW_THREAD_PORT = 0x20,
	// The task port is borrowed, not owned by the threadexec object. The port reference count
	// is not changed, so the client is responsible for managing the lifetime of the task port.
	TX_BORROW_TASK_PORT   = 0x40,
	// Both TX_BORROW_THREAD_PORT and TX_BORROW_TASK_PORT.
	TX_BORROW_PORTS       = TX_BORROW_THREAD_PORT | TX_BORROW_TASK_PORT,
	// The thread port is a bare Mach thread with no associated pthread state. Use this flag
	// for a thread created via thread_create().
	TX_BARE_THREAD        = 0x80,
};

typedef uint32_t tx_create_flags_t;

/*
 * threadexec_init
 *
 * Description:
 * 	Initialize a threadexec_t context to execute code in the context of a thread and task.
 *
 * Parameters:
 * 	task				The task in which to set up the execution context. This may
 * 					be a task right or a task_inspect right.
 * 	thread				The thread in which to set up the execution context. The
 * 					thread will be consumed for use by this execution context
 * 					and will be terminated when the threadexec object is
 * 					destroyed (unless TX_PRESERVE is supplied). Pass
 * 					MACH_PORT_NULL to try and create a new thread in the task.
 * 	flags				Creation/behavior flags.
 *
 * Returns:
 * 	Returns a new threadexec_t object on success and NULL on failure.
 *
 * Notes:
 * 	On success, this function takes ownership of the supplied task and thread ports. If you
 * 	need to keep them alive independently of the threadexec_t object, add a reference to the
 * 	ports before calling this function or supply the TX_BORROW_PORTS flag.
 *
 * 	Destroy the threadexec_t object by calling threadexec_deinit() when it is no longer needed.
 * 	Destroying the threadexec object will terminate the controlled thread unless TX_PRESERVE is
 * 	supplied.
 *
 * 	The supplied task must not be suspended and the thread must be suspended with a suspend
 * 	count of 1. If thread hijacking is not being used, other threads in the task may be
 * 	suspended.
 */
threadexec_t threadexec_init(task_t task, thread_t thread, tx_create_flags_t flags);

/*
 * threadexec_deinit
 *
 * Description:
 * 	Destroys a threadexec_t object, releasing all associated resources and terminating the
 * 	remote thread.
 */
void threadexec_deinit(threadexec_t threadexec);

/*
 * threadexec_task
 *
 * Description:
 * 	Get the Mach task port for the controlled task.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 *
 * Returns:
 * 	The Mach port for the task. This may be a task_t or task_inspect_t right, or MACH_PORT_NULL
 * 	if no task was supplied.
 */
mach_port_t threadexec_task(threadexec_t threadexec);

/*
 * threadexec_task_remote
 *
 * Description:
 * 	Return the remote name for the task. That is, return the task's name for its own task port
 * 	in its own IPC space.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 *
 * Returns:
 * 	The task's Mach port name for itself.
 */
mach_port_t threadexec_task_remote(threadexec_t threadexec);

/*
 * threadexec_thread
 *
 * Description:
 * 	Get the Mach thread port for the controlled thread.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 *
 * Returns:
 * 	The Mach port for the thread.
 */
mach_port_t threadexec_thread(threadexec_t threadexec);

/*
 * threadexec_thread_remote
 *
 * Description:
 * 	Return the remote name for the thread. That is, return the task's name for this thread port
 * 	in its own IPC space.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 *
 * Returns:
 * 	The task's Mach port name for the controlled thread.
 */
mach_port_t threadexec_thread_remote(threadexec_t threadexec);

/*
 * threadexec_call_fast
 *
 * Description:
 * 	Call a function with the given arguments. Function calling is limited to the arguments
 * 	that can be passed in registers.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	result			out	On return, contains the return value of the called
 * 					function.
 * 	result_size			The size of the function's return value in bytes. Must be a
 * 					power of 2 no greater than the platform word size.
 * 	function			The address of the remote function to execute. Pass 0 to
 * 					test if the specified function call would be supported.
 * 	argument_count			The number of arguments to the function.
 * 	arguments			The array of arguments to the function.
 *
 * Returns:
 * 	Returns true on success.
 *
 * Notes:
 * 	This function should not be used to call variadic functions.
 *
 * 	Non-integer arguments are not supported.
 *
 * TODO:
 * 	Add support for variadic functions.
 *
 * 	Add support for non-integer arguments (e.g. double).
 */
bool threadexec_call_fast(threadexec_t threadexec, void *result, size_t result_size,
		const void *function, unsigned argument_count, const word_t *arguments);

/*
 * threadexec_call
 *
 * Description:
 * 	Call a function with the given arguments.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	result			out	On return, contains the return value of the called
 * 					function.
 * 	result_size			The size of the function's return value in bytes. Must be a
 * 					power of 2 no greater than the platform word size.
 * 	function			The address of the remote function to execute. Pass 0 to
 * 					test if the specified function call would be supported.
 * 	argument_count			The number of arguments to the function.
 * 	arguments			The array of arguments to the function.
 *
 * Returns:
 * 	Returns true on success.
 *
 * Notes:
 * 	This function should not be used to call variadic functions.
 *
 * 	Non-integer arguments are not supported.
 *
 * TODO:
 * 	Add support for variadic functions.
 *
 * 	Add support for non-integer arguments (e.g. double).
 */
bool threadexec_call(threadexec_t threadexec, void *result, size_t result_size,
		const void *function, unsigned argument_count,
		const struct threadexec_call_argument *arguments);

/*
 * threadexec_call_c
 *
 * Description:
 * 	Call a function with the given arguments. Arguments are annotated with common usage
 * 	conventions for C-style functions to simplify calling remote functions.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	result			out	On return, contains the return value of the called
 * 					function.
 * 	result_size			The size of the function's return value in bytes. Must be a
 * 					power of 2 no greater than the platform word size.
 * 	function			The address of the remote function to execute. Pass 0 to
 * 					test if the specified function call would be supported.
 * 	argument_count			The number of arguments to the function.
 * 	arguments			The array of arguments to the function. These must be
 * 					declared using the TX_CARG_* macros.
 *
 * Returns:
 * 	Returns true on success.
 *
 * Notes:
 * 	This function should not be used to call variadic functions.
 *
 * 	Non-integer arguments are not supported.
 *
 * TODO:
 * 	Add support for variadic functions.
 *
 * 	Add support for non-integer arguments (e.g. double).
 */
bool threadexec_call_c(threadexec_t threadexec, void *result, size_t result_size,
		const void *function, unsigned argument_count,
		const struct threadexec_call_c_argument *arguments);

/*
 * threadexec_call_cv
 *
 * Description:
 * 	Call a function with the given arguments. Arguments are annotated with common usage
 * 	conventions for C-style functions to simplify calling remote functions.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	result			out	On return, contains the return value of the called
 * 					function.
 * 	result_size			The size of the function's return value in bytes. Must be a
 * 					power of 2 no greater than the platform word size.
 * 	function			The address of the remote function to execute. Pass 0 to
 * 					test if the specified function call would be supported.
 * 	argument_count			The number of arguments to the function.
 * 	...				The arguments to the function. These must be declared using
 * 					the TX_CARG_* macros.
 *
 * Returns:
 * 	Returns true on success.
 *
 * Notes:
 * 	This function should not be used to call variadic functions.
 *
 * 	Non-integer arguments are not supported.
 *
 * TODO:
 * 	Add support for variadic functions.
 *
 * 	Add support for non-integer arguments (e.g. double).
 *
 * 	Clean up naming convention.
 */
bool threadexec_call_cv(threadexec_t threadexec, void *result, size_t result_size,
		const void *function, unsigned argument_count, ...);

/*
 * threadexec_shared_vm_default
 *
 * Description:
 * 	Get the default shared memory region.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	remote_address		out	On return, the address of the default shared memory region
 * 					in the remote thread.
 * 	local_address		out	On return, the address of the default shared memory region
 * 					in the local task.
 * 	size			out	On return, the size of the default shared memory region.
 *
 * Notes:
 * 	The default shared memory region is guaranteed to be at least 0x8000 bytes.
 */
void threadexec_shared_vm_default(threadexec_t threadexec,
		const void **remote_address, void **local_address, size_t *size);

/*
 * threadexec_shared_vm_allocate
 *
 * Description:
 * 	Allocate a region of virtual memory that is shared between the current task and the remote
 * 	thread.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	remote_address		out	On return, the address of the shared memory region in the
 * 					remote thread.
 * 	local_address		out	On return, the address of the shared memory region in the
 * 					local task.
 * 	size				The size of the shared memory region to allocate.
 *
 * Returns:
 * 	Returns true on success.
 */
bool threadexec_shared_vm_allocate(threadexec_t threadexec,
		const void **remote_address, void **local_address, size_t size);

/*
 * threadexec_shared_vm_deallocate
 *
 * Description:
 * 	Deallocate a shared virtual memory region allocated with threadexec_vm_allocate.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	remote_address			The address of the shared memory region in the remote
 * 					thread.
 * 	local_address			The address of the shared memory region in the local task.
 * 	size				The size of the shared memory region to allocate.
 *
 * Returns:
 * 	Returns true on success.
 *
 * TODO:
 * 	Try to use the task functions first, then fall back on the thread ones.
 */
void threadexec_shared_vm_deallocate(threadexec_t threadexec,
		const void *remote_address, void *local_address, size_t size);

/*
 * threadexec_mach_vm_deallocate
 *
 * Description:
 * 	A wrapper around mach_vm_deallocate().
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	remote_address			The remote address of the virtual memory region.
 * 	size				The size of the memory region.
 *
 * Returns:
 * 	Returns true on success.
 */
bool threadexec_mach_vm_deallocate(threadexec_t threadexec,
		const void *remote_address, size_t size);

/*
 * threadexec_read
 *
 * Description:
 * 	Read memory from the remote thread into a local buffer.
 *
 * Parameters:
 * 	remote_address			The address in the remote thread to read.
 * 	data				The local buffer that will be filled with the memory
 * 					contents of the remote thread.
 * 	size				The number of bytes to read.
 *
 * Returns:
 * 	Returns true on success.
 *
 * TODO:
 * 	Try to use the task functions first, then fall back on the thread ones.
 */
bool threadexec_read(threadexec_t threadexec,
		const void *remote_address, void *data, size_t size);

/*
 * threadexec_write
 *
 * Description:
 * 	Write memory from a local buffer into the remote thread.
 *
 * Parameters:
 * 	remote_address			The address in the remote thread to write.
 * 	data				The local buffer containing the data to write.
 * 	size				The number of bytes to write.
 *
 * Returns:
 * 	Returns true on success.
 *
 * TODO:
 * 	Try to use the task functions first, then fall back on the thread ones.
 */
bool threadexec_write(threadexec_t threadexec,
		const void *remote_address, const void *data, size_t size);

/*
 * threadexec_mach_port_extract
 *
 * Description:
 * 	Copy the Mach port with the specified port name from the remote thread to the local task.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	remote_port_name		The Mach port name of the remote port.
 * 	local_port		out	On return, a copy of the remote Mach port.
 * 	disposition			The IPC type describing how to transfer the right.
 *
 * Returns:
 * 	Returns true on success.
 */
bool threadexec_mach_port_extract(threadexec_t threadexec,
		mach_port_name_t remote_port_name, mach_port_t *local_port,
		mach_msg_type_name_t disposition);

/*
 * threadexec_mach_port_insert
 *
 * Description:
 * 	Copy the specified Mach port from the local task to the remote thread.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	local_port			The Mach port to send.
 * 	remote_port_name	out	On return, the Mach port name of the remote copy of the
 * 					port.
 * 	disposition			The IPC type describing how to transfer the right.
 *
 * Returns:
 * 	Returns true on success.
 */
bool threadexec_mach_port_insert(threadexec_t threadexec,
		mach_port_t local_port, mach_port_name_t *remote_port_name,
		mach_msg_type_name_t disposition);

/*
 * threadexec_mach_port_deallocate
 *
 * Description:
 * 	Call mach_port_deallocate() in the threadexec task to deallocate the specified Mach port.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	remote_port_name		The remote task's name for the Mach port.
 *
 * Returns:
 * 	Returns true on success.
 */
bool threadexec_mach_port_deallocate(threadexec_t threadexec,
		mach_port_t remote_port_name);

/*
 * threadexec_file_insert
 *
 * Description:
 * 	Insert the specified local file into the threadexec process.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	local_fd			The local file descriptor of the file to send to the remote
 * 					process.
 * 	remote_fd		out	On return, the remote process's file descriptor for the
 * 					file.
 *
 * Returns:
 * 	Returns true on success.
 *
 * TODO:
 * 	Not implemented.
 */
bool threadexec_file_insert(threadexec_t threadexec, int local_fd, int *remote_fd);

/*
 * threadexec_file_extract
 *
 * Description:
 * 	Copy a file in the threadexec process to the local process.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	remote_fd			The file descriptor of the file in the remote process to
 * 					copy.
 * 	local_fd		out	On return, the file descriptor for the file in the local
 * 					process.
 *
 * Returns:
 * 	Returns true on success.
 */
bool threadexec_file_extract(threadexec_t threadexec, int remote_fd, int *local_fd);

/*
 * threadexec_file_open
 *
 * Description:
 * 	Open a file in a threadexec process. If remote_fd is NULL, then the file is closed in the
 * 	remote process. If local_fd is not NULL, then the file is copied to the local process.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	path				The path of the file to open.
 * 	oflags				Flags to open().
 * 	mode				The open() mode.
 * 	remote_fd		out	If not NULL, on return, the file descriptor for the opened
 * 					file in the threadexec process. If NULL, the remote file
 * 					descriptor is closed.
 * 	local_fd			If not NULL, on return, the file descriptor for the opened
 * 					file in the local process. If NULL, the remote file is not
 * 					copied to the local process.
 *
 * Returns:
 * 	Returns true on success.
 */
bool threadexec_file_open(threadexec_t threadexec, const char *path, int oflags, mode_t mode,
		int *remote_fd, int *local_fd);

/*
 * threadexec_file_close
 *
 * Description:
 * 	Close a file descriptor in a threadexec process.
 *
 * Parameters:
 * 	threadexec			The threadexec context.
 * 	remote_fd			The remote file descriptor to close.
 *
 * Returns:
 * 	Returns true on success.
 */
bool threadexec_file_close(threadexec_t threadexec, int remote_fd);

/*
 * threadexec_log
 *
 * Description:
 * 	This is the log handler that will be executed when an thread_call function wants to log a
 * 	message. The default implementation logs the message to stderr. Setting this value to NULL
 * 	will disable all logging. Specify a custom log handler to process log messages in another
 * 	way.
 *
 * Parameters:
 * 	type				A character representing the type of message that is being
 * 					logged.
 * 	format				A printf-style format string describing the error message.
 * 	ap				The variadic argument list for the format string.
 *
 * Log Type:
 * 	The type parameters is one of:
 * 	- D: Debug:     Used for debugging messages. Set the DEBUG build variable to control debug
 * 	                verbosity.
 * 	- I: Info:      Used to convey general information about the exploit or its progress.
 * 	- W: Warning:   Used to indicate that an unusual but recoverable condition was encountered.
 * 	- E: Error:     Used to indicate that an unrecoverable error was encountered. The current
 * 			thread_call might continue running after an error was encountered, but it
 * 			almost certainly will not succeed.
 */
extern void (*threadexec_log)(char type, const char *format, va_list ap);

#endif
