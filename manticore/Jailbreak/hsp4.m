//
//  tfp0.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include <mach/mach.h>
#include "../Exploit/cicuta_virosa.h"
#include "../Misc/kernel_offsets.h"
#include "hsp4.h"
#include "patchfinder64.h"
#include <stddef.h>
#include <mach/thread_status.h>
#include <pthread/pthread.h>
#include "../Libraries/IOKit/IOKitLib.h"
#include "../Libraries/Bazad/IOSurface.h"

#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/mach_traps.h>
#include <mach/kern_return.h>

uint32_t tfp0_port = 0;
mach_vm_size_t pagesize = 0;


uint64_t KernelLeak_portAddr(uint64_t target_task, uint32_t portname){
    // Leak kernel ipc port stru address of the input port
    
    uint64_t leaked_port_stru_kAddr = 0;
    
    mach_port_t stored_ports[3] = {0};
    stored_ports[0] = mach_task_self();
    stored_ports[2] = portname;
    mach_ports_register(mach_task_self(), stored_ports, 3);
    
    leaked_port_stru_kAddr = read_32(target_task + 0x308 + 0x10);
    
    stored_ports[2] = 0;
    mach_ports_register(mach_task_self(), stored_ports, 3);
    
    return leaked_port_stru_kAddr;
}

void patch_tf_platform(uint64_t target_task){
    uint32_t old_t_flags = read_32(target_task + koffset(KSTRUCT_OFFSET_TASK_TFLAGS));
    old_t_flags |= 0x00000400; // TF_PLATFORM
    //write_32bits(target_task + koffset(KSTRUCT_OFFSET_TASK_TFLAGS), (const void *)&old_t_flags);
}

mach_port_t patch_retrieve_tfp0(){
    tfp0_port = 0;
    task_get_special_port(mach_task_self(), TASK_ACCESS_PORT, &tfp0_port); // TASK_ACCESS_PORT is 8 in ios13 (for non-PAC), for PAC is 9
    return tfp0_port;
}

int set_hsp4(uint64_t self_task){
    mach_port_t self_mach_port_t = new_mach_port();
    printf("self_mach_port_t:\t0x%x\n", self_mach_port_t);
    return 0;
}


mach_port_t task_for_pid_workaround(int Pid) {
  
  host_t        myhost = mach_host_self(); // host self is host priv if you're root anyway..
  mach_port_t   psDefault;
  mach_port_t   psDefault_control;

  task_array_t  tasks;
  mach_msg_type_number_t numTasks;
  int i;

   thread_array_t       threads;
   thread_info_data_t   tInfo;

  kern_return_t kr;

  kr = processor_set_default(myhost, &psDefault);

  kr = host_processor_set_priv(myhost, psDefault, &psDefault_control);
 if (kr != KERN_SUCCESS) { fprintf(stderr, "host_processor_set_priv failed with error %x\n", kr);
         mach_error("host_processor_set_priv",kr); exit(1);}

  printf("So far so good\n");

  kr = processor_set_tasks(psDefault_control, &tasks, &numTasks);
  if (kr != KERN_SUCCESS) { fprintf(stderr,"processor_set_tasks failed with error %x\n",kr); exit(1); }

  for (i = 0; i < numTasks; i++)
        {
                int pid;
                pid_for_task(tasks[i], &pid);
                printf("TASK %d PID :%d\n", i,pid);
                if (pid == Pid) return (tasks[i]);
        }

   return (MACH_PORT_NULL);
} // end workaround
