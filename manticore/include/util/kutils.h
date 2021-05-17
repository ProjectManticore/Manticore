//
//  kutils.h
//  manticore
//
//  Created by admin on 7/3/21.
//

#ifndef kutils_h
#define kutils_h

#include <inttypes.h>
#include <xnu/iokit/IOKit/IOTypes.h>

typedef unsigned long long addr_t;
typedef uint64_t kptr_t;

typedef mach_port_t vm_map_t;

#define KPTR_NULL ((kptr_t) 0)
#define VM_MIN_KERNEL_ADDRESS   0xffffffe000000000ULL
#define VM_MAX_KERNEL_ADDRESS   0xfffffff3ffffffffULL
#define KERN_POINTER_VALID(val) (((val) & 0xffffffff) != 0xdeadbeef && (val) >= VM_MIN_KERNEL_ADDRESS && (val) <= VM_MAX_KERNEL_ADDRESS)
#define KERN_POINTER_INVALID(val) (!KERN_POINTER_VALID(val))

#define TF_PLATFORM 0x00000400 /* task is a platform binary */


#endif /* kutils_h */
