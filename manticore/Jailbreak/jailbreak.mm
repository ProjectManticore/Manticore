//
//  jailbreak.m
//  reton
//
//  Created by Luca on 15.02.21.
//

#include "ViewController.h"
#include <UIKit/UIKit.h>
#include <sys/sysctl.h>
#include <sys/snapshot.h>
#include <mach/mach.h>
#include <Foundation/Foundation.h>
#include "lib/tq/iosurface.h"
#include "lib/tq/kapi.h"
#include "lib/tq/k_offsets.h"
#include "lib/tq/tq_common_p.h"
#include "lib/tq/utils.h"
#include "lib/tq/k_utils.h"
#include "exploit/cicuta/cicuta_virosa.h"
#include "exploit/cicuta/exploit_main.h"
#include "manticore/amfid.h"
#include "manticore/hsp4.h"
#include "manticore/kernel_utils.h"
#include "manticore/jailbreak.h"
#include "manticore/rootfs.h"
#include "manticore/utils.h"
#include "amfid_patches.h"
#include "util/plistutils.h"
#include "xnu/libsyscall/wrappers/libproc/libproc.h"


extern "C" int jailbreak() {
    printf("* ------- Applying Patches ------- *\n");
    struct proc_cred *old_cred;
    proc_set_root_cred(g_exp.self_proc, &old_cred);
    util_msleep(100);
    int err = setuid(0);
    if (err) perror("setuid");
    patch_TF_PLATFORM(g_exp.self_task);
    uint64_t csflags = read_32(g_exp.self_proc + OFFSET(proc, csflags));
    uint64_t csflags_mod = (csflags|0xA8|0x0000008|0x0000004|0x10000000)&~(0x0000800|0x0000100|0x0000200);
    printf("CS Flags:\t0x%llx | 0x%llx\n", csflags, csflags_mod);
    // AMFID PATCHES
    fuckup_amfid();

    printf("Goodbye!\n");
    return 0;
}

bool check_sandbox_escape(void){
    [[NSFileManager defaultManager] createFileAtPath:@"/var/mobile/escaped" contents:nil attributes:nil];
    if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/escaped"]){
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/escaped" error:nil];
        return true;
    } else {
        return false;
    }
}

int install_bootstrap(void){
    return 0;
}

int sb_allow_ndefault(void) {
    // Allow SpringBoard to show non-default system apps.
    if(modifyPlist(@"/var/mobile/Library/Preferences/com.apple.springboard.plist", ^(id plist) { plist[@"SBShowNonDefaultSystemApps"] = @YES; }))
        return 1;
    return 0;
}

bool setup_manticore_filesystem(void){
    NSString *jailbreakDirBasePath  = @"/var/mobile/.manticore/";
    NSString *jailbreakPlistPath    = [NSString stringWithFormat:@"%@jailbreak.plist", jailbreakDirBasePath];
    if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/.manticore/"] && [[NSFileManager defaultManager]  fileExistsAtPath:jailbreakPlistPath]) {
        return YES;
    } else {
        printf("initial installation of manticore starting...\n");
            
        // Create /var/mobile/.manticore folder for jailbreak/project specific files
        if(![[NSFileManager defaultManager] fileExistsAtPath:jailbreakDirBasePath]) [[NSFileManager defaultManager] createDirectoryAtPath:jailbreakDirBasePath withIntermediateDirectories:YES attributes:nil error:NULL];
        else return NO;
            
        // Create jailbreak.plist
        if(![[NSFileManager defaultManager] fileExistsAtPath:jailbreakPlistPath]) createEmptyPlist(jailbreakPlistPath);
        else return NO;
        return 0;
    }
    return NO;
}
