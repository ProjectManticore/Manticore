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
#include "../include/util/mach_vm.h"

#include <mach/mach_traps.h>
#include <mach/mach_init.h>
#include <mach/host_special_ports.h>
#include <mach/mach_error.h>
#import <mach/mach_types.h>
#include <mach/mach.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread/pthread.h>

pthread_attr_t pth_commAttr = {0};

void pth_commAttr_init(){
    pthread_attr_init(&pth_commAttr);
    pthread_attr_setdetachstate(&pth_commAttr, PTHREAD_CREATE_DETACHED);
}

/**
	binary_load_address(mach_port_t target_port) ---> returns kptr_t object/addresss
		 Function to find the binary load address of amfid in memory.
**/

kptr_t binary_load_address(mach_port_t target_port){
    // TODO: fix this shit
    return KPTR_NULL;
}


void* amfid_exception_handler(void* arg){
    return NULL;
}

void set_exception_handler(mach_port_t amfid_task_port){
    // allocate a port to receive exceptions on:
    mach_port_t amfid_exception_port = cv_new_mach_port();
    kern_return_t err = task_set_exception_ports(amfid_task_port,
                                                 EXC_MASK_ALL,
                                                 amfid_exception_port,
                                                 EXCEPTION_DEFAULT | MACH_EXCEPTION_CODES,  // we want to receive a catch_exception_raise message with the thread port for the crashing thread
                                                 6);
    
    if (err != KERN_SUCCESS){
        (printf)("error setting amfid exception port: %s\t(%d)\n", mach_error_string(err), err);
    } else {
        (printf)("set amfid exception port: succeed!\n");
    }
    
    pthread_t exception_thread;
    pthread_create(&exception_thread, &pth_commAttr, amfid_exception_handler, NULL);
}

/***
 Replace the Original Amfid task port with a custom one, created by us. (https://github.com/bazad/blanket/blob/22d670d25b8ab5ad569c3f8f4de108ae8e0b6e0a/amfidupe/amfidupe.c#L93)
 */

bool replace_amfid_port(){
	mach_port_t real_amfid_port, fake_amfid_port;
	mach_port_t host = mach_host_self();
	kern_return_t kr = host_get_amfid_port(host, &real_amfid_port);
	if (kr != KERN_SUCCESS) {
		manticore_error("Could not get amfid's service port!\n");
		return false;
	}
	mach_port_options_t options = { .flags = MPO_INSERT_SEND_RIGHT };
	kr = mach_port_construct(mach_task_self(), &options, 0, &fake_amfid_port);
	if (kr != KERN_SUCCESS) {
		manticore_error("Could not create fake amfid port!\n");
		return false;
	}
	kr = host_set_amfid_port(host, fake_amfid_port);
	if (kr != KERN_SUCCESS) {
		manticore_error("Could not register fake amfid port: error %d\n", kr);
		return false;
	}
	manticore_info("Registered new amfid port: 0x%x\n", fake_amfid_port);
	return true;
}

kptr_t perform_amfid_patches(){
    printf("* ------- AMFID Patches -------- *\n");
    if(getuid() != 0) return 1;
    mach_port_t amfid_task_port = MACH_PORT_NULL;
    kern_return_t ret = host_get_amfid_port(mach_host_self(), &amfid_task_port);
    if(ret == KERN_SUCCESS){
        printf("amfid port:\t0x%x\n", amfid_task_port);
        set_exception_handler(amfid_task_port);
        kptr_t amfid_base = binary_load_address(amfid_task_port);
        printf("amfid base:\t0x%llx\n", amfid_base);
	} else manticore_error("Could not get amfid's service port!\n");
    return 0;
}
