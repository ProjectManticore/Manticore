//
//  jailbreak.h
//  reton
//
//  Created by Luca on 15.02.21.
//


#ifndef jailbreak_h
#define jailbreak_h

#include "../Exploit/cicuta_virosa.h"

int jailbreak();
bool setup_manticore_filesystem(void);
uint64_t root_patch(uint64_t task_pac);
int sb_allow_ndefault(void);
bool check_sandbox_escape(void);

#endif /* jailbreak_h */
