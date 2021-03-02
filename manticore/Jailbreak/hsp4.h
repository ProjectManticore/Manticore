//
//  tfp0.h
//  reton
//
//  Created by Luca on 18.02.21.
//

#ifndef tfp0_h
#define tfp0_h

extern
kern_return_t mach_vm_read_overwrite
(
    vm_map_t target_task,
    mach_vm_address_t address,
    mach_vm_size_t size,
    mach_vm_address_t data,
    mach_vm_size_t *outsize
);

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

mach_port_t task_for_pid_workaround(int Pid);

#endif /* tfp0_h */
