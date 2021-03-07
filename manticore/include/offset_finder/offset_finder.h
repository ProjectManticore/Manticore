//
//  offset_finder.h
//  manticore
//
//  Created by admin on 8/3/21.
//

#ifndef offset_finder_h
#define offset_finder_h

#ifdef __cplusplus
extern "C" {
#endif

kptr_t find_kernel_task(void *kbase, size_t ksize)
void init_offset_finder()

#ifdef __cplusplus
}
#endif

#endif /* offset_finder_h */
