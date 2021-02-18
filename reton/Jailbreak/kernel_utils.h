//
//  kernel_utils.h
//  reton
//
//  Created by Luca on 18.02.21.
//

#ifndef kernel_utils_h
#define kernel_utils_h

kptr_t get_proc_struct_for_pid(pid_t pid);
bool set_platform_binary(kptr_t proc, bool set);
#endif /* kernel_utils_h */
