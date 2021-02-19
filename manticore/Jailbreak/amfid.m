//
//  amfid.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include "../Exploit/cicuta_virosa.h"
#include "utils.h"
#include <mach/mach_traps.h>
#include <mach/mach_init.h>
#include <mach/mach_error.h>
#include <mach/mach.h>


uint64_t perform_amfid_patches(uint64_t cr_label){
    printf("\n[================] AMFID Patches [================]\n");
    uint32_t uid = getuid();
    if(uid != 0) return 1;
//    printf("Trying to patch amfid slot...\n");
//    printf("amfid slot found -> 0x%llx\n", read_64(cr_label + 0x8));
    printf("==> backboardd pid\t\t--->\t%d\n", pid_of_process("/usr/libexec/backboardd"));
    pid_t amfid_pid = pid_of_process("/usr/libexec/amfid");
    printf("==> amfid's pid\t\t\t--->\t%d\n", amfid_pid);
    printf("==> Getting task_port...\n");
    mach_port_t amfid_task_port;
    kern_return_t kr = task_for_pid(mach_task_self(), amfid_pid, &amfid_task_port);
    if (kr) {
        printf("==> Failed to get amfid's task :(\n\tError: %s\n", mach_error_string(kr));
        return -1;
    }
    if (!MACH_PORT_VALID(amfid_task_port)) {
            printf("==> Failed to get amfid's task port!\n");
            return -1;
    }
    printf("==> Got amfid's task port? :) 0x%x\n", amfid_task_port);

    return 0;
}
