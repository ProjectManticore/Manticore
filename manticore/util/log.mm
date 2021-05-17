//
//  log.m
//  manticore
//
//  Created by fugiefire on 7/3/21.
//

#include <util/log.hpp>
#include <util/error.hpp>

#include <stdlib.h>
#include <string.h>
#include <pthread.h>

#import <Foundation/Foundation.h>

/* ugh i forgot stack has a lifetime so most of this is useless atm
 * todo: add functionality to return a uuid for each registered var, and be able to deregister them
 * then, add macros on function prologue/epilogue to automatically handle registery removal
 * - fugiefire */

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

void _manticore_output_dump_var(NSString *fmt, ...) {
    /* we need a way to have NSLog but without newlines at the end */
    va_list l;
    va_start(l, fmt);
    NSString *string;
    string = [[NSString alloc] initWithFormat:fmt arguments:l];
    va_end(l);
    printf("%s", [string UTF8String]);
}

void _manticore_output_dump_var_entry(_manticore_var_dump_entry_t *entry) {
    if (entry == NULL) {
        NSLog(@"<NULL ENTRY>\n");
        return;
    }
        
#define _MANTICORE_OUTPUT_ARRAY(fmt, a){\
NSDateComponents *datecomp = [[NSCalendar currentCalendar] components:NSCalendarUnitNanosecond|NSCalendarUnitSecond|NSCalendarUnitMinute|NSCalendarUnitHour|NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:[NSDate date]];\
/* this incantation should give Y-M-D h:m:s:n+a 4 digit number for time offset */\
_manticore_output_dump_var(@"%d-%d-%d %d:%d:%d:%d+%d%d ", [datecomp year], [datecomp month], [datecomp day], [datecomp hour], [datecomp minute], [datecomp second], [datecomp nanosecond], [[NSTimeZone localTimeZone] secondsFromGMT] / 3600, ([[NSTimeZone localTimeZone] secondsFromGMT] / 3600.0 - ([[NSTimeZone localTimeZone] secondsFromGMT] / 3600)) * 100 / 5 * 3);\
_manticore_output_dump_var(@"%s[%d:%lu]", [[NSProcessInfo processInfo] processName], [[NSProcessInfo processInfo] processIdentifier], pthread_mach_thread_np(pthread_self()));\
_manticore_output_dump_var(@"Array<char>[%llu]: {", entry->len);\
for (int i = 0; i < entry->len; i++) {\
NSLog(fmt, a[i]);\
}}\
_manticore_output_dump_var(@"\b\b}\n");
    
    if (entry->pretty_name != NULL) {
        switch (entry->type) {
            case MANTICORE_DUMP_C: NSLog(@"%c {%02x} (%s)", entry->c, entry->c, entry->pretty_name); break;
            case MANTICORE_DUMP_I8: NSLog(@"%hhi {%02hhx} (%s)", entry->i8, entry->i8, entry->pretty_name); break;
            case MANTICORE_DUMP_U8: NSLog(@"%hhu {%02hhx} (%s)", entry->u8, entry->u8, entry->pretty_name); break;
            case MANTICORE_DUMP_I16: NSLog(@"%hi {%04hx} (%s)", entry->i16, entry->i16, entry->pretty_name); break;
            case MANTICORE_DUMP_U16: NSLog(@"%hu {%04hx} (%s)", entry->u16, entry->u16, entry->pretty_name); break;
            case MANTICORE_DUMP_I32: NSLog(@"%li {%08lx} (%s)", entry->i32, entry->i32, entry->pretty_name); break;
            case MANTICORE_DUMP_U32: NSLog(@"%lu {%08lx} (%s)", entry->u32, entry->u32, entry->pretty_name); break;
            case MANTICORE_DUMP_I64: NSLog(@"%lli {%016llx} (%s)", entry->i64, entry->i64, entry->pretty_name); break;
            case MANTICORE_DUMP_U64: NSLog(@"%llu {%016llx} (%s)", entry->u64, entry->u64, entry->pretty_name); break;
            case MANTICORE_DUMP_F32: NSLog(@"%f (%s)", entry->f32, entry->pretty_name); break;
            case MANTICORE_DUMP_F64: NSLog(@"%lf (%s)", entry->f64, entry->pretty_name); break;
            case MANTICORE_DUMP_F128: NSLog(@"%Lf (%s)", entry->f128, entry->pretty_name); break;
            case MANTICORE_DUMP_PTR: NSLog(@"%p (%s)", entry->ptr, entry->pretty_name); break;
            case MANTICORE_DUMP_C_ARR: _MANTICORE_OUTPUT_ARRAY(@"%c, ", entry->c_arr); break;
            case MANTICORE_DUMP_I8_ARR: _MANTICORE_OUTPUT_ARRAY(@"%02hhx, ", entry->i8_arr); break;
            case MANTICORE_DUMP_U8_ARR: _MANTICORE_OUTPUT_ARRAY(@"%02hhx, ", entry->u8_arr); break;
            case MANTICORE_DUMP_I16_ARR: _MANTICORE_OUTPUT_ARRAY(@"%04hx, ", entry->i16_arr); break;
            case MANTICORE_DUMP_U16_ARR: _MANTICORE_OUTPUT_ARRAY(@"%04hx, ", entry->u16_arr); break;
            case MANTICORE_DUMP_I32_ARR: _MANTICORE_OUTPUT_ARRAY(@"%08lx, ", entry->i32_arr); break;
            case MANTICORE_DUMP_U32_ARR: _MANTICORE_OUTPUT_ARRAY(@"%08lx, ", entry->u32_arr); break;
            case MANTICORE_DUMP_I64_ARR: _MANTICORE_OUTPUT_ARRAY(@"%016llx, ", entry->i64_arr); break;
            case MANTICORE_DUMP_U64_ARR: _MANTICORE_OUTPUT_ARRAY(@"%016llx, ", entry->u64_arr); break;
            case MANTICORE_DUMP_F32_ARR: _MANTICORE_OUTPUT_ARRAY(@"%f, ", entry->f32_arr); break;
            case MANTICORE_DUMP_F64_ARR: _MANTICORE_OUTPUT_ARRAY(@"%lf, ", entry->f64_arr); break;
            case MANTICORE_DUMP_F128_ARR: _MANTICORE_OUTPUT_ARRAY(@"%Lf, ", entry->f128_arr); break;
            case MANTICORE_DUMP_PTR_ARR: _MANTICORE_OUTPUT_ARRAY(@"%p, ", entry->ptr_arr); break;
            case MANTICORE_DUMP_STR: NSLog(@"%s", entry->str);
            default:
                NSLog(@"<UNKNOWN ENTRY TYPE>");
                return;
        }
    } else {
        switch (entry->type) {
            case MANTICORE_DUMP_C: NSLog(@"%c {%02x}", entry->c, entry->c);
            case MANTICORE_DUMP_I8: NSLog(@"%hhi {%02hhx}", entry->i8, entry->i8);
            case MANTICORE_DUMP_U8: NSLog(@"%hhu {%02hhx}", entry->u8, entry->u8);
            case MANTICORE_DUMP_I16: NSLog(@"%hi {%04hx}", entry->i16, entry->i16);
            case MANTICORE_DUMP_U16: NSLog(@"%hu {%04hx}", entry->u16, entry->u16);
            case MANTICORE_DUMP_I32: NSLog(@"%li {%08lx}", entry->i32, entry->i32);
            case MANTICORE_DUMP_U32: NSLog(@"%lu {%08lx}", entry->u32, entry->u32);
            case MANTICORE_DUMP_I64: NSLog(@"%lli {%016llx}", entry->i64, entry->i64);
            case MANTICORE_DUMP_U64: NSLog(@"%llu {%016llx}", entry->u64, entry->u64);
            case MANTICORE_DUMP_F32: NSLog(@"%f", entry->f32);
            case MANTICORE_DUMP_F64: NSLog(@"%lf", entry->f64);
            case MANTICORE_DUMP_F128: NSLog(@"%Lf", entry->f128);
            case MANTICORE_DUMP_PTR: NSLog(@"%p", entry->ptr);
            case MANTICORE_DUMP_C_ARR: _MANTICORE_OUTPUT_ARRAY(@"%c, ", entry->c_arr); break;
            case MANTICORE_DUMP_I8_ARR: _MANTICORE_OUTPUT_ARRAY(@"%02hhx, ", entry->i8_arr); break;
            case MANTICORE_DUMP_U8_ARR: _MANTICORE_OUTPUT_ARRAY(@"%02hhx, ", entry->u8_arr); break;
            case MANTICORE_DUMP_I16_ARR: _MANTICORE_OUTPUT_ARRAY(@"%04hx, ", entry->i16_arr); break;
            case MANTICORE_DUMP_U16_ARR: _MANTICORE_OUTPUT_ARRAY(@"%04hx, ", entry->u16_arr); break;
            case MANTICORE_DUMP_I32_ARR: _MANTICORE_OUTPUT_ARRAY(@"%08lx, ", entry->i32_arr); break;
            case MANTICORE_DUMP_U32_ARR: _MANTICORE_OUTPUT_ARRAY(@"%08lx, ", entry->u32_arr); break;
            case MANTICORE_DUMP_I64_ARR: _MANTICORE_OUTPUT_ARRAY(@"%016llx, ", entry->i64_arr); break;
            case MANTICORE_DUMP_U64_ARR: _MANTICORE_OUTPUT_ARRAY(@"%016llx, ", entry->u64_arr); break;
            case MANTICORE_DUMP_F32_ARR: _MANTICORE_OUTPUT_ARRAY(@"%f, ", entry->f32_arr); break;
            case MANTICORE_DUMP_F64_ARR: _MANTICORE_OUTPUT_ARRAY(@"%lf, ", entry->f64_arr); break;
            case MANTICORE_DUMP_F128_ARR: _MANTICORE_OUTPUT_ARRAY(@"%Lf, ", entry->f128_arr); break;
            case MANTICORE_DUMP_PTR_ARR: _MANTICORE_OUTPUT_ARRAY(@"%p, ", entry->ptr_arr); break;
            case MANTICORE_DUMP_STR: NSLog(@"%s", entry->str);
            default:
                NSLog(@"<UNKNOWN ENTRY TYPE>");
                return;
        }
    }
}

#pragma mark -- public functions

/* C bindings */
void manticore_register_dump_var_type_v_len_name(enum manticore_var_dump_type type,
                                                 void *v,
                                                 unsigned long long len,
                                                 const char *pretty_name) {
    manticore_register_dump_var(type, v, len, pretty_name);
}
void manticore_register_dump_var_type_v(enum manticore_var_dump_type type,
                                        void *v,
                                        unsigned long long len,
                                        const char *pretty_name) {
    manticore_register_dump_var(type, v);
}
void manticore_register_dump_var_type_v_name(enum manticore_var_dump_type type,
                                             void *v,
                                             unsigned long long len,
                                             const char *pretty_name) {
    manticore_register_dump_var(type, v, pretty_name);
}
void manticore_register_dump_var_type_v_len(enum manticore_var_dump_type type,
                                            void *v,
                                            unsigned long long len,
                                            const char *pretty_name) {
    manticore_register_dump_var(type, v, len);
}


bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v) {
    return manticore_register_dump_var(type, v, 1, NULL);
}

bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v, const char *pretty_name) {
    return manticore_register_dump_var(type, v, 1, pretty_name);
}

bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v, unsigned long long len) {
    return manticore_register_dump_var(type, v, len, NULL);
}

bool manticore_register_dump_var(enum manticore_var_dump_type type, void *v, unsigned long long len, const char *pretty_name) {
    /* sanity check */
    if (v == NULL) return false;
    if (len == 0) return false;
    if (type > _MANTICORE_DUMP_END || type < _MANTICORE_DUMP_START) return false;
    
    _manticore_add_empty_dump_entry();
    _manticore_var_dump_entry_t *entry = _manticore_dump_list->_tail;
    entry->type = type;
    entry->len = len;
    if (pretty_name) {
        entry->pretty_name = (char *)malloc(strlen(pretty_name) + 1);
        memcpy(entry->pretty_name, pretty_name, strlen(pretty_name) + 1);
    } else {
        entry->pretty_name = NULL;
    }
    
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
    
    _manticore_var_dump_entry_t *cur = NULL;
    if (_manticore_dump_list != NULL) {
        cur = _manticore_dump_list->_head;
    }
    
    NSLog(@"====== BEGIN VAR DUMP ======");
    while (cur != NULL) {
        _manticore_output_dump_var_entry(cur);
        cur = cur->_next;
    }
    NSLog(@"====== END VAR DUMP ======");
    
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
