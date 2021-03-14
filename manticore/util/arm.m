//
//  arm.m
//  manticore
//
//  Created by 21 on 14.03.21.
//

#import <Foundation/Foundation.h>
#include "include/lib/tq/tq_common_p.h"
#include "include/util/arm.h"

int is_pac() {
    return g_exp.has_PAC;
}
