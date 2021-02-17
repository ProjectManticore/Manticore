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
int setup_filesystem(void);
bool check_root_rw(void);

#endif /* jailbreak_h */
