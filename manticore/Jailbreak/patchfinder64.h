//
//  patchfinder64.h
//  manticore
//
//  Created by 21 on 20.02.21.
//

#ifndef patchfinder64_h
#define patchfinder64_h

uint64_t find_allproc(void);
uint64_t find_kernel_base(uint64_t proc_pointer);

#endif /* patchfinder64_h */
