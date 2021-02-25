//
//  OffsetFinder.m
//  manticore
//
//  Created by Luca on 25.02.21.
//

#import <Foundation/Foundation.h>
#include "support.h"
#include "Common.h"
#include "Utils.h"

kptr_t calc_kernel_map_from_task(kptr_t kernel_task){
    if(!strcmp(g_exp.osversion, "18C66")) return kernel_task + 0x3C98;
    return 0;
}

kptr_t calc_kernel_task_from_map(kptr_t kernel_map){
    if(!strcmp(g_exp.osversion, "18C66")) return kernel_map - 0x3C98;
    return 0;
}
