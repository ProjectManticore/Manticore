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

uint64_t find_allproc(void) {
    uint64_t val = 0, KernDumpBase = 0, KASLR_Slide = 0;
    return val + KernDumpBase + KASLR_Slide;
}
