//
//  arm64.c
//  manticore
//
//  Created by 21 on 10.03.21.
//

#include <stdio.h>
#include <strings.h>
#include <mach/machine.h>
#include <sys/sysctl.h>
#include <malloc/_malloc.h>
#include "include/util/arm64.h"

#ifndef CPU_SUBTYPE_ARM64E
#define CPU_SUBTYPE_ARM64E              ((cpu_subtype_t) 2)
#endif

cpu_subtype_t get_cpu_subtype() {
    cpu_subtype_t ret = 0;
    cpu_subtype_t *cpu_subtype = NULL;
    size_t *cpu_subtype_size = NULL;
    cpu_subtype = (cpu_subtype_t *)malloc(sizeof(cpu_subtype_t));
    bzero(cpu_subtype, sizeof(cpu_subtype_t));
    cpu_subtype_size = (size_t *)malloc(sizeof(size_t));
    bzero(cpu_subtype_size, sizeof(size_t));
    *cpu_subtype_size = sizeof(cpu_subtype_size);
    if (sysctlbyname("hw.cpusubtype", cpu_subtype, cpu_subtype_size, NULL, 0) != 0) return 0;
    ret = *cpu_subtype;
    return ret;
}


int is_arm64e() {
    return get_cpu_subtype() == CPU_SUBTYPE_ARM64E ? 0 : 1;
}

