//
//  log.hpp
//  manticore
//
//  Created by fugiefire on 7/3/21.
//

#ifndef _util_log_h
#define _util_log_h

enum manticore_log_level {
    LOG_DEBUG,
    LOG_INFO,
    LOG_WARN,
    LOG_ERROR,
    LOG_FATAL
};

enum manticore_var_dump_type {
    _MANTICORE_DUMP_START,
    
    /* non array types */
        /* char types */
        MANTICORE_DUMP_C,
    
        /* integer types */
        MANTICORE_DUMP_I8,
        MANTICORE_DUMP_U8,
        MANTICORE_DUMP_I16,
        MANTICORE_DUMP_U16,
        MANTICORE_DUMP_I32,
        MANTICORE_DUMP_U32,
        MANTICORE_DUMP_I64,
        MANTICORE_DUMP_U64,
        
        /* fp types */
        MANTICORE_DUMP_F32,
        MANTICORE_DUMP_F64,
        MANTICORE_DUMP_F128,
        
        /* pointer types */
        MANTICORE_DUMP_PTR,
    
    /* array types (todo: VLAs) */
        /* char types */
        MANTICORE_DUMP_C_ARR,

        /* integer types */
        MANTICORE_DUMP_I8_ARR,
        MANTICORE_DUMP_U8_ARR,
        MANTICORE_DUMP_I16_ARR,
        MANTICORE_DUMP_U16_ARR,
        MANTICORE_DUMP_I32_ARR,
        MANTICORE_DUMP_U32_ARR,
        MANTICORE_DUMP_I64_ARR,
        MANTICORE_DUMP_U64_ARR,
        
        /* fp types */
        MANTICORE_DUMP_F32_ARR,
        MANTICORE_DUMP_F64_ARR,
        MANTICORE_DUMP_F128_ARR,
        
        /* pointer types */
        MANTICORE_DUMP_PTR_ARR,
    
    /* other */
        MANTICORE_DUMP_STR,
    
    _MANTICORE_DUMP_END
};

/*!
 @function manticore_register_dump_var
 Registers a variable that will be dumped on a non recoverable exception
 
 @param type
 The type of variable to be added.
 For char: MANTICORE_DUMP_C
 For 32 bit signed int: MANTICORE_DUMP_I32
 For 128 bit IEEE754: MANTICORE_DUMP_F128
 etc
 For arrays, append the _ARR suffix to the type
 
 @param v
 A pointer to the variable to be registered
 
 @param len
 If this variable is an array, set this to the length of the array, else set this to 1
 
 @param pretty_name
 When dumping the state, if a pretty name is supplied then the pretty name will be printed alongside the variable
*/
bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v, unsigned long long len, const char *pretty_name);
bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v);
bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v, const char *pretty_name);
bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v, unsigned long long len);

#ifdef __cplusplus
extern "C" {
#endif

/*!
 @function manticore_throw
 Throws a non catchable error, will not return
 
 @param fmt
 Format string, like passed to functions such as `printf`, `sprintf` etc
 
 @param ...
 variadic args
 */
__attribute__((noreturn)) void manticore_throw(const char *fmt, ...);
/*!
 @function manticore_(error|warn|info|debug)
 Prints a (error|warn|info|debug) message
 
 @param fmt
 Format string, like passed to functions such as `printf`, `sprintf` etc
 
 @param ...
 variadic args
 */
void manticore_error(const char *fmt, ...);
void manticore_warn(const char *fmt, ...);
void manticore_info(const char *fmt, ...);
void manticore_debug(const char *fmt, ...);

/* when calling from C, only 4 arg variant is available */
void manticore_register_dump_var_type_v_len_name(enum manticore_var_dump_type type, void *v, unsigned long long len, const char *pretty_name);
void manticore_register_dump_var_type_v(enum manticore_var_dump_type type, void *v, unsigned long long len, const char *pretty_name);
void manticore_register_dump_var_type_v_name(enum manticore_var_dump_type type, void *v, unsigned long long len, const char *pretty_name);
void manticore_register_dump_var_type_v_len(enum manticore_var_dump_type type, void *v, unsigned long long len, const char *pretty_name);

#ifdef __cplusplus
}
#endif

#endif /* log_h */
