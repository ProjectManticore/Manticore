//
//  amfid.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include "exploit/cicuta/cicuta_virosa.h"
#include "exploit_utilities.h"

#include "utils.h"
#include "k_utils.h"
#include "tq_common_p.h"
#include "kapi.h"

#include "log.hpp"

#include <mach/mach_traps.h>
#include <mach/mach_init.h>
#include <mach/host_special_ports.h>
#include <mach/mach_error.h>
#import <mach/mach_types.h>
#include <mach/mach.h>
#include <stdio.h>
#include <stdlib.h>


kptr_t binary_load_address(mach_port_t target_port){
    return KPTR_NULL;
}

kptr_t perform_amfid_patches(){
    printf("* ------- AMFID Patches -------- *\n");
    if(getuid() != 0) return 1;
    mach_port_t amfid_task_port = MACH_PORT_NULL;
    kern_return_t ret = host_get_amfid_port(mach_host_self(), &amfid_task_port);
    if(ret == KERN_SUCCESS){
        printf("amfid port:\t0x%x\n", amfid_task_port);
        kptr_t amfid_base = binary_load_address(amfid_task_port);
        printf("amfid base:\t0x%llx\n", amfid_base);

    }
    return 0;
}
