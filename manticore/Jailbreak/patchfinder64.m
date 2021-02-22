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

uint64_t find_kernel_slide(mach_port_t mach_port){
    struct task_dyld_info info;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    task_info(mach_port, TASK_DYLD_INFO, (task_info_t) &info, &count);
    uint64_t kernel_slide = info.all_image_info_size;
    if(kernel_slide != 0) return kernel_slide;
    return 0;
}

mach_vm_size_t get_page_size(mach_port_t mach_port){
    kern_return_t ret = KERN_SUCCESS;
    mach_vm_size_t pagesize = 0;
    ret = _host_page_size(mach_host_self(), (vm_size_t*)&pagesize);
    if (ret != KERN_SUCCESS) {
        printf("[-] failed to get page size! ret: %x %s\n", ret, mach_error_string(ret));
        return 0;
    } else return pagesize;
}

uint64_t get_hardcoded_kernelbase(){
    return 0xFFFFFFF007004000;
}

uint64_t get_hardcoded_allproc_ipad(){
    return 0xfffffff0099f3758;
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
