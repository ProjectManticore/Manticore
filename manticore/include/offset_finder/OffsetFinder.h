//
//  OffsetFinder.h
//  manticore
//
//  Created by Luca on 25.02.21.
//

#ifndef OffsetFinder_h
#define OffsetFinder_h

#include "util/kutils.h"

#ifdef __cplusplus
extern "C" {
#endif

kptr_t calc_kernel_map(kptr_t kernel_task);
kptr_t calc_kernel_task(kptr_t kernel_map);

kptr_t find_kernel_base(kptr_t start_address);

addr_t find_symbol(const char *symbol);
kptr_t find_register_value(uint64_t where, int reg);
//kptr_t find_reference(uint64_t to, int n, enum text_bases base);
//kptr_t find_strref(const char *string, int n, enum string_bases string_base, bool full_match, bool ppl_base);
//kptr_t find_str(const char *string, int n, enum string_bases string_base, bool full_match, bool ppl_base);

#ifdef __cplusplus
}
#endif

#endif /* OffsetFinder_h */
