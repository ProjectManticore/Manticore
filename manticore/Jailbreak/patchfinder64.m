//
//  patchfinder64.m
//  manticore
//
//  Created by 21 on 20.02.21.
//

#include <Foundation/Foundation.h>
#include <assert.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <mach-o/fat.h>
#include "libproc.h"
#include <mach-o/loader.h>
#include "patchfinder64.h"
#include "../Libraries/IOKit/IOKit.h"
#include "../Misc/support.h"
#include "../Misc/kernel_offsets.h"
#include "../Exploit/cicuta_virosa.h"


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

uint64_t get_hardcoded_allproc_ipad(){
    return 0xfffffff0099f3758;
}

uint64_t find_port_via_kmem_read(mach_port_name_t port, kptr_t task_self_addr) {
   uint64_t task_port_addr = task_self_addr;
   uint64_t task_addr = read_64(task_port_addr + koffset(KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT));
   uint64_t itk_space = read_64(task_addr + 0x308);
   uint64_t is_table = read_64(itk_space + 0x20);

   uint32_t port_index = port >> 8;
   const int sizeof_ipc_entry_t = 0x18;

   uint64_t port_addr = read_64(is_table + (port_index * sizeof_ipc_entry_t));
   return port_addr;
}

void find_task_by_pid(pid_t pid){
    printf("[*]\ttrying to find process with pid = %d\n", pid);
    int pidCount = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    unsigned long pidsBufSize = sizeof(pid_t) * (unsigned long)pidCount;
    pid_t * pids = malloc(pidsBufSize);
    bzero(pids, pidsBufSize);
    proc_listpids(PROC_ALL_PIDS, 0, pids, (int)pidsBufSize);
    char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
    for (int i=0; i < pidCount; i++) {
        bzero(pathBuffer, PROC_PIDPATHINFO_MAXSIZE);
        proc_pidpath(pids[i], pathBuffer, sizeof(pathBuffer));
        if (pids[i] == pid) break;
    }
    printf("[*]\tFound process called '%s'\n", pathBuffer);
}

pid_t * get_all_pids(){
    int pidCount = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    unsigned long pidsBufSize = sizeof(pid_t) * (unsigned long)pidCount;
    pid_t * pids = malloc(pidsBufSize);
    bzero(pids, pidsBufSize);
    proc_listpids(PROC_ALL_PIDS, 0, pids, (int)pidsBufSize);
    char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
    for (int i=0; i < pidCount; i++) {
            bzero(pathBuffer, PROC_PIDPATHINFO_MAXSIZE);
            proc_pidpath(pids[i], pathBuffer, sizeof(pathBuffer));
            printf("pid %d = %s\n", pids[i], pathBuffer);
    }
    return pids;
}

uint64_t dump_kernel(mach_port_t tfp0, uint64_t kernel_base, kptr_t task_self_addr) {
    printf("[*]\tTrying to dump kernel...\n");
   mach_port_t self = mach_host_self();
   uint64_t port_addr = find_port_via_kmem_read(self, task_self_addr);
   uint64_t search_addr = read_64(port_addr + 0x68); //KSTRUCT_OFFSET_IPC_PORT_IP_KOBJECT
   search_addr &= 0xFFFFFFFFFFFFF000;
   printf("[+]\tGoing backwards until magic seen....\n");
   while (1) {
       if (read_32(search_addr) == 0xfeedfacf) {
           printf("[+]\tOk, looks like we've found the beginning of the kernel!\n");
           printf("[+]\tKERNEL IS AT 0x%llx\n", search_addr);
           printf("[+]\tKASLR detected to be 0x%llx\n", search_addr + 0x6060a0 - kernel_base);
           return search_addr;
       } else {
           search_addr -= 0x1000;
       }
   }
}

kptr_t find_kernel_base(uint64_t proc_pointer, kptr_t task_addr) {
    kptr_t itk_space = read_64(task_addr + 0x320);
    kptr_t is_table = read_64(itk_space + 0x20);
    const int sizeof_ipc_entry_t = 0x18;
    
    for(kptr_t i = 0; i < 10; i++){
        kptr_t port_addr = read_64(is_table + (i * sizeof_ipc_entry_t));
        printf("Potential task address:\t0x%llx\t\t(0x%llx)\n", port_addr, is_table + (i * sizeof_ipc_entry_t));
    }

    // TODO: Choose good method
    //    io_service_t service = IO_OBJECT_NULL;
    //    mach_port_t client = MACH_PORT_NULL;
    //    service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOSurfaceRoot"));
    //    if(!MACH_PORT_VALID(service)) return 1;
    //    if(!IOServiceOpen(service, mach_task_self(), 0, &client)) return 2;
    //    if(!MACH_PORT_VALID(client)) return 3;
    //    if(!KERN_POINTER_VALID(proc_pointer)) return 4;
    //    printf("Successfully found kernelBase: %d", 21);
    //    return 0x10;
    return 0;
}

