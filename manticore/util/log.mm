//
//  log.m
//  manticore
//
//  Created by fugiefire on 7/3/21.
//

#include "util/log.hpp"
#include "util/error.hpp"

#include <stdlib.h>
#include <string.h>

#import <Foundation/Foundation.h>

#pragma mark -- private func decls
void _manticore_log_out(enum manticore_log_level level, const char *s);
void _manticore_add_empty_dump_entry();
void _manticore_dump_init();

#pragma mark -- private defs
typedef struct _manticore_var_dump_entry _manticore_var_dump_entry_t;
struct _manticore_var_dump_entry {
    enum manticore_var_dump_type type;
    union {
        /* non array types */
        union {
            /* char types */
            union {
                char c;
            };
            /* integer types */
            union {
                signed char i8;
                unsigned char u8;
                signed short i16;
                unsigned short u16;
                signed long i32;
                unsigned long u32;
                signed long long i64;
                unsigned long long u64;
            };
            /* fp types */
            union {
                float f32;
                double f64;
                long double f128;
            };
            /* ptr types */
            union {
                void *ptr;
            };
        };
        
        /* fixed length array types */
        union {
            /* char types */
            union {
                char *c_arr;
            };
            /* integer types */
            union {
                signed char *i8_arr;
                unsigned char *u8_arr;
                signed short *i16_arr;
                unsigned short *u16_arr;
                signed long *i32_arr;
                unsigned long *u32_arr;
                signed long long *i64_arr;
                unsigned long long *u64_arr;
            };
            /* fp types */
            union {
                float *f32_arr;
                double *f64_arr;
                long double *f128_arr;
            };
            /* ptr types */
            union {
                void **ptr_arr;
            };
        };
        
        /* other types */
        union {
            char *str;
        };
    };
    
    unsigned long long len;
    char *pretty_name;
    
    struct _manticore_var_dump_entry *_next;
};

typedef struct {
    _manticore_var_dump_entry_t *_head;
    _manticore_var_dump_entry_t *_tail;
} _manticore_var_dump_list_t;

_manticore_var_dump_list_t *_manticore_dump_list = NULL;

#pragma mark -- private vars
static enum manticore_log_level _default_log_level;
static const char *_log_level_strs[] = {
    "[DEBUG]",
    "[INFO]",
    "[WARN]",
    "[ERROR]",
    "[FATAL]"
};

#pragma mark -- private functions
void _manticore_log_out(enum manticore_log_level level, const char *s) {
    MANTICORE_THROW_ON_NULL(s);
    NSLog(@"%s %s", _log_level_strs[level], s);
}

void _manticore_add_empty_dump_entry() {
    MANTICORE_THROW_ON_NULL(_manticore_dump_list);
    _manticore_var_dump_entry_t *entry;
    entry = (_manticore_var_dump_entry_t *)malloc(sizeof(*entry));
    memset(entry, 0, sizeof(*entry));
    MANTICORE_THROW_ON_NULL(entry);
    
    if (_manticore_dump_list->_tail == NULL) {
        _manticore_dump_list->_head = _manticore_dump_list->_tail = entry;
    } else {
        _manticore_dump_list->_tail->_next = entry;
        _manticore_dump_list->_tail = entry;
    }
}

void _manticore_dump_init() {
    /* inits the single linked list */
    if (_manticore_dump_list != NULL) return;
    _manticore_dump_list = (_manticore_var_dump_list_t *)malloc(sizeof(*_manticore_dump_list));
    MANTICORE_THROW_ON_NULL(_manticore_dump_list);
    
    _manticore_dump_list->_head = _manticore_dump_list->_tail = NULL;
}

#pragma mark -- public functions
bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v) {
    return manticore_register_dump_var(type, v, 1);
}

bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v, const char *pretty_name) {
    return manticore_register_dump_var(type, v, 1, pretty_name);
}

bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v, unsigned long long len) {
    return manticore_register_dump_var(type, v, len, "(unknown)");
}

bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v, unsigned long long len, const char *pretty_name) {
    /* sanity check */
    if (v == NULL) return false;
    if (pretty_name == NULL) return false;
    if (len == 0) return false;
    if (type > _MANTICORE_DUMP_END || type < _MANTICORE_DUMP_START) return false;
    
    _manticore_add_empty_dump_entry();
    _manticore_var_dump_entry_t *entry = _manticore_dump_list->_tail;
    entry->type = type;
    entry->len = len;
    entry->pretty_name = (char *)malloc(strlen(pretty_name) + 1);
    memcpy(entry->pretty_name, pretty_name, strlen(pretty_name) + 1);
    
    switch (type) {
        case MANTICORE_DUMP_C: entry->c = *(char *)v; break;
        case MANTICORE_DUMP_I8: entry->i8 = *(signed char *)v; break;
        case MANTICORE_DUMP_U8: entry->u8 = *(unsigned char *)v; break;
        case MANTICORE_DUMP_I16: entry->i16 = *(signed short *)v; break;
        case MANTICORE_DUMP_U16: entry->u16 = *(unsigned short *)v; break;
        case MANTICORE_DUMP_I32: entry->i32 = *(signed long *)v; break;
        case MANTICORE_DUMP_U32: entry->u32 = *(unsigned long *)v; break;
        case MANTICORE_DUMP_I64: entry->i64 = *(signed long long *)v; break;
        case MANTICORE_DUMP_U64: entry->u64 = *(unsigned long long *)v; break;
        case MANTICORE_DUMP_F32: entry->f32 = *(float *)v; break;
        case MANTICORE_DUMP_F64: entry->f64 = *(double *)v; break;
        case MANTICORE_DUMP_F128: entry->f128 = *(long double *)v; break;
        case MANTICORE_DUMP_PTR: entry->ptr = v; break;
        case MANTICORE_DUMP_C_ARR: entry->c_arr = (char *)v; break;
        case MANTICORE_DUMP_I8_ARR: entry->i8_arr = (signed char *)v; break;
        case MANTICORE_DUMP_U8_ARR: entry->u8_arr = (unsigned char *)v; break;
        case MANTICORE_DUMP_I16_ARR: entry->i16_arr = (signed short *)v; break;
        case MANTICORE_DUMP_U16_ARR: entry->u16_arr = (unsigned short *)v; break;
        case MANTICORE_DUMP_I32_ARR: entry->i32_arr = (signed long *)v; break;
        case MANTICORE_DUMP_U32_ARR: entry->u32_arr = (unsigned long *)v; break;
        case MANTICORE_DUMP_I64_ARR: entry->i64_arr = (signed long long *)v; break;
        case MANTICORE_DUMP_U64_ARR: entry->u64_arr = (unsigned long long *)v; break;
        case MANTICORE_DUMP_F32_ARR: entry->f32_arr = (float *)v; break;
        case MANTICORE_DUMP_F64_ARR: entry->f64_arr = (double *)v; break;
        case MANTICORE_DUMP_F128_ARR: entry->f128_arr = (long double *)v; break;
        case MANTICORE_DUMP_PTR_ARR: entry->ptr_arr = (void **)v; break;
        case MANTICORE_DUMP_STR: entry->str = (char *)v; entry->len = strlen(entry->str); break;
        default:
            return false;
    }
    
    return true;
}

void manticore_set_default_log_level(enum manticore_log_level level) {
    _default_log_level = level;
}

#define _MANTICORE_LOG_COMMON(type, arg)\
char *s = NULL;\
va_list l;\
va_start(l, arg);\
if (vasprintf(&s, arg, l) != -1) {\
_manticore_log_out(type, s);\
}\
va_end(l);

__attribute__((noreturn)) void manticore_throw(const char *fmt, ...) {
    _MANTICORE_LOG_COMMON(LOG_FATAL, fmt);
    
    /* todo: register/dump vars */
    exit(EXIT_FAILURE);
}

void manticore_error(const char *fmt, ...) {_MANTICORE_LOG_COMMON(LOG_ERROR, fmt); }
void manticore_warn(const char *fmt, ...) { _MANTICORE_LOG_COMMON(LOG_WARN, fmt);  }
void manticore_info(const char *fmt, ...) { _MANTICORE_LOG_COMMON(LOG_INFO, fmt);  }
void manticore_debug(const char *fmt, ...) {_MANTICORE_LOG_COMMON(LOG_DEBUG, fmt); }

void manticore_log_init() {
    _manticore_dump_init();
    manticore_set_default_log_level(LOG_DEBUG);
}
