//
//  offset_finder.h
//  manticore
//
//  Created by admin on 8/3/21.
//

#ifndef offset_finder_h
#define offset_finder_h

kptr_t find_kernel_task(void *kbase, size_t ksize);
void init_offset_finder();

#endif /* offset_finder_h */
