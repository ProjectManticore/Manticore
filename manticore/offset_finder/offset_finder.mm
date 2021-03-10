/*
    kernel_task offset finder for cicuta_virosa, untested
    (c) fugiefire 01/03/2021
*/

#include <stdbool.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <limits.h>
#include "k_offsets.h"
#include "log.hpp"
#include "../include/lib/tq/kapi.h"

/* define this to 0 when reading from live mem, 1 when testing on a decompressed kcache */
#define TESTENV 0
#define KBASE 0xFFFFFFF007004000
#define KSIZE 0x0000000003000000

typedef uint64_t kptr_t;

#if TESTENV
void kapi_read(kptr_t addr, void *data, size_t len) { memcpy(data, (void*)addr, len); }
uint32_t kapi_read32(kptr_t addr) { return *(uint32_t *)addr; }
uint64_t kapi_read64(kptr_t addr) { return *(uint64_t *)addr; }
#else
extern void kapi_read(kptr_t addr, void *data, size_t len);
extern uint32_t kapi_read32(kptr_t addr);
extern uint64_t kapi_read64(kptr_t addr);
#endif

/* wrappers for future proofing */
void        _kread(void *p, char *r, size_t n)  { return kapi_read((kptr_t)p, (void *)r, n); }
uint32_t    _kread_32(void *p)                  { return kapi_read32((kptr_t)p); }
uint64_t    _kread_64(void *p)                  { return kapi_read64((kptr_t)p); }

/****** BMH ALGORITHM ******/
/* https://en.wikipedia.org/wiki/Boyer%E2%80%93Moore%E2%80%93Horspool_algorithm */

void _bmh_table_gen(unsigned char const *needle, const size_t needle_len,
                    size_t table[]) {
    for (int i = 0; i <= UCHAR_MAX; i++)
        table[i] = needle_len;
    for (int i = 0; i < needle_len - 1; i++)
        table[needle[i]] = needle_len - 1 - i;
}

void *bmh_search(unsigned char const *needle, const size_t needle_len,
                unsigned char *haystack, size_t haystack_len) {
    size_t table[UCHAR_MAX + 1] = {0};
    _bmh_table_gen(needle, needle_len, table);

    while (haystack_len >= needle_len) {
        for (size_t i = needle_len - 1; haystack[i] == needle[i]; i--)
            if (i == 0) return (void *)haystack;

        haystack_len -= table[haystack[needle_len - 1]];
        haystack += table[haystack[needle_len - 1]];

        fflush(stdout);
    }

    return NULL;
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
    UNK = 0, ADRP = 1, ADD
};

/* starting to regret not using capstone */
enum aarch64_insn_type get_insn_type(aarch64_insn_t insn) {
         if ((insn & 0x9F000000) == 0x90000000) return ADRP;
    else if ((insn & 0xFF000000) == 0x91000000) return ADD;
    else return UNK;
}

long long _extract_adrp_imm(u64 off, aarch64_insn_t insn, int print) {
    /* extract immhi:immlo from adrp */
    u32 immhi = insn & 0xFFFFE0;
    immhi <<= 8;

    u32 immlo = insn & 0x60000000;
    immlo >>= 18;

    long long imm = immhi | immlo;
    imm <<= 1;

    /* sign extend */
    /* this is very shit */
    if (imm & 0x100000000) imm += 0xFFFFFFFE00000000;

    /* add pc relative */
    imm += (off & ~0xFFF);

    return imm;
}

u32 _extract_add_imm(aarch64_insn_t insn) {
    u32 imm = insn & 0x3FFC00;
    imm >>= 10;
    switch ((insn >> 22) & 0b11) { // check if shift is set
        case 0b00:
            break;
        case 0b01:
            imm <<= 12;
        case 0b10: /* this means the insn is addg, so get_insn_type didn't work properly */
        case 0b11:
        default:
            /* throw? */
            break;
    }
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
            case ADRP: {
                u64 imm = _extract_adrp_imm((u64)haystack + (u64)from, cur_insn, 0);

                /* ADRP could directly xref our ref if it's page aligned */
                if (imm == (u64) ref)
                    return (void *)((u64)haystack + (u64)from);

                /* check if the next insn is an ADD */
                cur_insn = _kread_32((void *)((u64)haystack + (u64)from + 4));
                if (get_insn_type(cur_insn) != ADD)
                    break;

                imm |= _extract_add_imm(cur_insn);

                if (imm == (u64)ref)
                    return (void *)((u64)haystack + (u64)from);

                break;

            }
            default:
                break;
        }

        /* next insn */
        from = (void *)((u64)from + 4);
    }

    return NULL;
}


/** kernel_cred / kernel_vm_map finder **/

kptr_t get_kernel_cred_addr(kptr_t kernel_proc){
    kptr_t ret = KPTR_NULL;
    kptr_t kernel_proc_struct_addr = kernel_proc;
    if(KERN_POINTER_VALID(kernel_proc_struct_addr)){
        kptr_t kernel_ucred_struct_addr = kapi_read_kptr(kernel_proc_struct_addr + OFFSET(proc, p_ucred));
        if(KERN_POINTER_VALID(kernel_ucred_struct_addr)){
            ret = kernel_ucred_struct_addr;
        } else manticore_warn("Invalid kernel_ucred_struct_addr.\t\t(0x%llx)\n", kernel_ucred_struct_addr);
    } else manticore_warn("Invalid kernel_proc_struct_addr.\t\t(0x%llx)\n", kernel_proc_struct_addr);
    return ret;
}

kptr_t get_kernel_vm_map(kptr_t kernel_task){
    kptr_t ret = kapi_read_kptr(kernel_task + 0x28);;
    if(!KERN_POINTER_VALID(ret)) manticore_warn("Pointer invalid; kernel_vm_map!\t\t(0x%llx)\n", (kernel_task + 0x28));
    return ret;
}


/****** kernel_task finder ******/

// string to match
static const unsigned char *_IOGPUResource = (unsigned char *)"static IOGPUResource *IOGPUResource::newResourceWithOptions(IOGPU *, IOGPUDevice *, enum eIOGPUResType, uint64_t, IOByteCount, IOOptionBits, mach_vm_address_t *, IOGPUNewResourceArgs *)";
// address of ^
kptr_t p_IOGPUResource = 0;

kptr_t p_kernel_base = KBASE;
size_t v_kernel_size = KSIZE; // this is almost guaranteed to go beyond end of kernel



kptr_t find_kernel_task(void *kbase, size_t ksize) {
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

    p_IOGPUResource = (kptr_t) bmh_search(
                        _IOGPUResource, strlen((const char *)_IOGPUResource),
                        (unsigned char *)kbase, ksize);

#if TESTENV
    p_IOGPUResource -= (kptr_t) kbase;
    p_IOGPUResource += p_kernel_base;
#endif

    /* IOGPUResource::newResourceWithOptions */
    /* that same function has kernel_task at +D0 */
    kptr_t func_iogpuresource = (kptr_t)find_xref_to((void *)p_IOGPUResource, kbase, 0, (void *)ksize);
    /* backtrack to function prologue */
    func_iogpuresource = (kptr_t) bmh_search(
                            prologue_iogpuresource, sizeof(prologue_iogpuresource),
                            (unsigned char *)(func_iogpuresource - 0xF0), 0x500); /* 0x500 is way overshooting it as is */
    
    /* extract kernel_task from:
     * ADRP     X8, #_kernel_task@PAGE
     * ADD      X8, X8, #_kernel_task@PAGEOFF */
    aarch64_insn_t adrp_ktask = *((aarch64_insn_t *) (func_iogpuresource + 0xD0));
    aarch64_insn_t add_ktask = *((aarch64_insn_t *) (func_iogpuresource + 0xD4));
#if TESTENV
    printf("adrp_ktask: %p\nadd_ktask:  %p\n", (void *)((size_t)adrp_ktask), (void *)((size_t)add_ktask));
#endif
    
    kptr_t kernel_task = _extract_adrp_imm(func_iogpuresource + 0xD0, adrp_ktask, 1) | _extract_add_imm(add_ktask);
    return kernel_task;
}

void init_offset_finder(kptr_t kernel_base) {
    /* calculate kbase */
    kptr_t start = kernel_base;
    unsigned char macho_header[] = {
        0xCF, 0xFA, 0xED, 0xFE, /* 0xFEEDFACF */
        0x0C, 0x00, 0x00, 0x01, /* 0x0100000C */
#ifdef __arm64e__ /* switch on cpu subtype */
        0x02, 0x00, 0x00, 0xc0, /* 0xC0000002 */
#else
        0x00, 0x00, 0x00, 0x00, /* 0x00000000 */
#endif
        0x02, 0x00, 0x00, 0x00  /* 0x00000002 */
    };
    
    p_kernel_base = (kptr_t) bmh_search(macho_header, sizeof(macho_header), (unsigned char *)start, v_kernel_size);
}
