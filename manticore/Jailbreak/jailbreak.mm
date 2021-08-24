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
#include <lib/tq/iosurface.h>
#include <lib/tq/kapi.h>
#include <lib/tq/k_offsets.h>
#include <lib/tq/tq_common_p.h>
#include <lib/tq/utils.h>
#include <lib/tq/k_utils.h>
#include <exploit/cicuta/cicuta_virosa.h>
#include <exploit/cicuta/exploit_main.h>
#include <manticore/amfid.h>
#include <manticore/kernel_utils.h>
#include <manticore/jailbreak.h>
#include <manticore/rootfs.h>
#include <manticore/utils.h>
#include <util/plistutils.h>
#include <xnu/libsyscall/wrappers/libproc/libproc.h>

#define JAILB_ROOT "/private/var/containers/Bundle/jb_resources/"
static const char *jailb_root = JAILB_ROOT;
#define CPU_SUBTYPE_ARM64E              ((cpu_subtype_t) 2)

cpu_subtype_t get_cpu_subtype() {
    cpu_subtype_t ret = 0;
    cpu_subtype_t *cpu_subtype = NULL;
    size_t *cpu_subtype_size = NULL;
    cpu_subtype = (cpu_subtype_t *)malloc(sizeof(cpu_subtype_t));
    bzero(cpu_subtype, sizeof(cpu_subtype_t));
    cpu_subtype_size = (size_t *)malloc(sizeof(size_t));
    bzero(cpu_subtype_size, sizeof(size_t));
    *cpu_subtype_size = sizeof(cpu_subtype_size);
    if (sysctlbyname("hw.cpusubtype", cpu_subtype, cpu_subtype_size, NULL, 0) != 0) return 0;
    ret = *cpu_subtype;
    return ret;
}

#define IS_PAC (get_cpu_subtype() == CPU_SUBTYPE_ARM64E)

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
    prepare_fake_entitlements();
    self_macf = proc_fetch_MACF(g_exp.self_proc);
    patch_codesign();
    printf("Codessign patched");
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
        printf("Initial installation of manticore starting...\n");
            
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
