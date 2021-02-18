//
//  jailbreak.h
//  reton
//
//  Created by Luca on 15.02.21.
//


#ifndef jailbreak_h
#define jailbreak_h

#include <Foundation/Foundation.h>
#include "../Exploit/cicuta_virosa.h"

int jailbreak(void *init);
bool setup_manticore_filesystem(void);
bool check_root_rw(void);
uint64_t root_patch(uint64_t task_pac);
int sb_allow_ndefault(void);

#endif /* jailbreak_h */
