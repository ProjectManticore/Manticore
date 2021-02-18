//
//  amfid.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include "../Exploit/cicuta_virosa.h"

int amfid_patches(uint64_t cr_label){
    uint32_t uid = getuid();
    if(uid != 0) return 0;
    printf("Trying to patch amfid slot...\n");
    printf("amfid slot -> %llu", read_64(cr_label + 0x8));
    return 0;
}
