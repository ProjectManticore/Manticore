//
//  patchfinder64.h
//  manticore
//
//  Created by 21 on 20.02.21.
//

#ifndef patchfinder64_h
#define patchfinder64_h

    // ACTIVE / WORKING
uint64_t find_kernel_slide(mach_port_t mach_port);
mach_vm_size_t get_page_size(mach_port_t mach_port);

    // TODO / WIP
uint64_t find_kernel_task(uint64_t region, uint8_t* kdata, size_t ksize);


    // INCOMPLETE / BROKEN
uint64_t find_allproc(void);
uint64_t find_kernel_base(uint64_t proc_pointer);

#endif /* patchfinder64_h */
