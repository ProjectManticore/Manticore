//
//  offset_finder.h
//  manticore
//
//  Created by admin on 8/3/21.
//

#ifndef offset_finder_h
#define offset_finder_h

kptr_t get_kernel_cred_addr(kptr_t kernel_proc);
kptr_t get_kernel_vm_map(kptr_t kernel_task);

kptr_t find_kernel_task(void *kbase, size_t ksize);
void init_offset_finder(kptr_t kernel_base);

#endif /* offset_finder_h */
