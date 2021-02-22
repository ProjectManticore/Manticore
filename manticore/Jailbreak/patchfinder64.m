//
//  patchfinder64.m
//  manticore
//
//  Created by 21 on 20.02.21.
//

#import <Foundation/Foundation.h>
#import <assert.h>
#import <stdint.h>
#import <string.h>
#import <stdbool.h>
#import <mach-o/fat.h>
#include "patchfinder64.h"
#include "../Libraries/IOKit/IOKit.h"
#include "../Misc/support.h"


uint64_t find_allproc(void) {
    uint64_t val = 0, KernDumpBase = 0, KASLR_Slide = 0;
    return val + KernDumpBase + KASLR_Slide;
}

uint64_t find_kernel_base(uint64_t proc_pointer) {
    uint64_t kernel_base_pointer = 0;
    io_service_t service = IO_OBJECT_NULL;
    mach_port_t client = MACH_PORT_NULL;
    service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOSurfaceRoot"));
    if(!MACH_PORT_VALID(service)) return 1;
    if(!IOServiceOpen(service, mach_task_self(), 0, &client)) return 2;
    if(!MACH_PORT_VALID(client)) return 3;
    if(!KERN_POINTER_VALID(proc_pointer)) return 4;
    printf("Successfully found kernelBase: %d", 21);
    return 0x10;
}

uint64_t find_kernel_slide(){
    mach_port_t host = mach_host_self();
    if(!MACH_PORT_VALID(host)) return 0;
    uint64_t host_port;
    
    return 1;
}
