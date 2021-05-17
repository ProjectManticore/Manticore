//
//  error.hpp
//  manticore
//
//  Created by fugiefire on 7/3/21.
//

#ifndef error_h
#define error_h

#include <util/log.hpp>

/* handy macros for sanity checking */
/* fairly self explanatory */
#define MANTICORE_THROW_ON_FALSE_WITH_MSG(COND, M) if (!(COND)) { manticore_throw("assert failed (%s:%d): %s", __FILE__, __LINE__, M); }
#define MANTICORE_THROW_ON_FALSE(COND) MANTICORE_THROW_ON_FALSE_WITH_MSG(COND, #COND)
#define MANTICORE_THROW_ON_NULL(P) MANTICORE_THROW_ON_FALSE_WITH_MSG((P != NULL), #P " should not be null")

#endif /* error_h */
