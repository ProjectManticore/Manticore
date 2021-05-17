//
//  alloc.h
//  manticore
//
//  Created by fugiefire on 7/3/21.
//

#ifndef alloc_h
#define alloc_h

#include <util/error.hpp>

#define SafeFree(x) do { if (x) free(x); } while (false)
#define SafeFreeNULL(x) do { SafeFree(x); (x) = NULL; } while (false)

#define SafeAlloc(x, sz) do { x = (typeof(x))malloc(sizeof(*x)); MANTICORE_THROW_ON_NULL(x); } while (false)

#endif /* alloc_h */
