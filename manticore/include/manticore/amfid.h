//
//  amfid.h
//  reton
//
//  Created by Luca on 18.02.21.
//

#ifndef amfid_h
#define amfid_h

#ifdef __cplusplus
extern "C" {
#endif

kern_return_t mach_vm_region (vm_map_t target_task,
                                        mach_vm_address_t *address,
                                        mach_vm_size_t *size,
                                        vm_region_flavor_t flavor,
                                        vm_region_info_t info,
                                        mach_msg_type_number_t *infoCnt,
                                        mach_port_t *object_name);

#ifdef __cplusplus
}
#endif

kptr_t perform_amfid_patches();

#endif /* amfid_h */
