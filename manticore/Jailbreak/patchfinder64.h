//
//  patchfinder64.h
//  manticore
//
//  Created by 21 on 20.02.21.
//
#include "../Misc/support.h"



#ifndef patchfinder64_h
#define patchfinder64_h

    // ACTIVE / WORKING
uint64_t find_kernel_slide(mach_port_t mach_port);
mach_vm_size_t get_page_size(mach_port_t mach_port);
pid_t * get_all_pids();
    // TODO / WIP
uint64_t dump_kernel(mach_port_t tfp0, uint64_t kernel_base, kptr_t task_self_addr);
uint64_t find_port_via_kmem_read(mach_port_name_t port, kptr_t task_self_addr);

uint64_t find_kernel_task(uint64_t region, uint8_t* kdata, size_t ksize);


    // INCOMPLETE / BROKEN
uint64_t find_allproc(void);
kptr_t find_kernel_base(uint64_t proc_pointer, kptr_t task_addr);

#endif /* patchfinder64_h */
