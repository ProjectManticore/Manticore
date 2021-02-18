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
    printf("amfid slot found -> 0x%llx\n", read_64(cr_label + 0x8));
    printf("patching amfid...");
    uint32_t buffer[5] = {0, 0, 0, 1, 0};
    write_64(cr_label + 0x8, (void*)buffer);
    printf("\tdone (0x%llx)\n", read_64(cr_label + 0x8));
    return 0;
}
