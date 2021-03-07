//
//  tfp0.h
//  reton
//
//  Created by Luca on 18.02.21.
//

#ifndef tfp0_h
#define tfp0_h

#include "manticore/kernel_utils.h"

#ifdef __cplusplus
extern "C" {
#endif

extern
kern_return_t mach_vm_region_recurse
(
    vm_map_t target_task,
    mach_vm_address_t *address,
    mach_vm_size_t *size,
    natural_t *nesting_depth,
    vm_region_recurse_info_t info,
    mach_msg_type_number_t *infoCnt
);

int set_hsp4(uint64_t self_task);

#ifdef __cplusplus
}
#endif

#endif /* tfp0_h */
