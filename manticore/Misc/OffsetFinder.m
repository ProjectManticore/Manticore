//
//  OffsetFinder.m
//  manticore
//
//  Created by Rpwnage on 25.02.21.
//

/*
*       If you've just joined;
*       I'm rewriting OffsetFinder from scratch
*       Just using vscode because xcode wont let me show only this file.
*/

#import <Foundation/Foundation.h>
#include "support.h"
#include "Common.h"
#include "../Libraries/pattern_f/KernelAPI.h"
#include "Utils.h"

typedef uint64_t kptr_t;

kptr_t calc_kernel_map_from_task(kptr_t kernel_task){
    if(!strcmp(g_exp.osversion, "18C66")) return kernel_task + 0x3C98;
    return 0;
}

kptr_t calc_kernel_task_from_map(kptr_t kernel_map){
    if(!strcmp(g_exp.osversion, "18C66")) return kernel_map - 0x3C98;
    return 0;
}

addr_t find_kernel_task(kptr_t kernel_map){
    kptr_t target_address;
    int iteration_count;
    for(target_address = kernel_map, iteration_count = 0; target_address < 0xFFFFFFFFFFFFFFFF; target_address += 4, iteration_count++){
        // TODO: Add memory iteration and find kernel_task/offset (kernel_map?)
    }
    return 0;
}

kptr_t find_kernel_base(kptr_t start_address){
    kptr_t target_address;
    int iteration_count;
    for(target_address = start_address, iteration_count = 0; target_address < 0xFFFFFFFFFFFFFFFF; target_address += 4, iteration_count++){
        uint32_t data[4] = {};
        const uint32_t mach_header_arm64[4] = { 0xfeedfacf, 0x0100000c, 0, 2 };
        kapi_read(target_address, data, sizeof(mach_header_arm64));
        if(!memcmp(mach_header_arm64, data, sizeof(uint32_t [2]))){
            printf("kernel_base:\t\t0x%llx\t\t(%d iterations)\n", target_address, iteration_count);
            return target_address;
        }
    }
    printf("Unable to find Kernel_base :(\n");
    return 0;
}

addr_t find_symbol(const char *symbol_identifier){
    return 0;
}

kptr_t find_string_reference(const char *string, ...) {
    return 0x0;
}

kptr_t find_string(const char *string, ...) {
    return 0x0;
}

