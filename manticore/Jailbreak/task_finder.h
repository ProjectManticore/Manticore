//
//  task_finder.h
//  manticore
//
//  Created by 21 on 02.03.21.
//

#ifndef task_finder_h
#define task_finder_h
typedef uint64_t kptr_t;
uint64_t kbase_value(void);
kptr_t get_kernel_task(void *kbase, size_t ksize);

#endif /* task_finder_h */
