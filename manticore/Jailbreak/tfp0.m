//
//  tfp0.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include "../Exploit/cicuta_virosa.h"

mach_port_t gain_tfp0(uint64_t self_task){
    mach_port_t tfp0;
    printf("[i] Preparing to elevate own privileges!\n");
    uint64_t credentials = read_64(self_task + 0xf0);
    printf("[*] Own Task: 0x%llx\n", self_task);
    //e
    return tfp0;
}
