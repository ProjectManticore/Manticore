//
//  OffsetFinder.h
//  manticore
//
//  Created by Luca on 25.02.21.
//

#ifndef OffsetFinder_h
#define OffsetFinder_h

#include "support.h"

kptr_t calc_kernel_map_from_task(kptr_t kernel_task);
kptr_t calc_kernel_task_from_map(kptr_t kernel_map);

#endif /* OffsetFinder_h */
