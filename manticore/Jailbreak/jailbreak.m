//
//  jailbreak.m
//  reton
//
//  Created by Luca on 15.02.21.
//

#include "../ViewController.h"
#include <UIKit/UIKit.h>
#include <sys/sysctl.h>
#include <sys/snapshot.h>
#include <mach/mach.h>
#include <Foundation/Foundation.h>
#include "../Libraries/Bazad/IOSurface.h"
#include "../Libraries/pattern_f/KernelAPI.h"
#include "../Libraries/pattern_f/KernelOffsets.h"
#include "../Libraries/pattern_f/Common.h"
#include "../Libraries/pattern_f/Utils.h"
#include "../Libraries/pattern_f/KernelUtils.h"
#include "../Exploit/cicuta_virosa.h"
#include "../Exploit/exploit_main.h"
#include "../Misc/support.h"
#include "../Misc/OffsetFinder.h"
#include "../Misc/kernel_offsets.h"
#include "kernel_utils.h"
#include "amfid.h"
#include "hsp4.h"
#include "kernel_utils.h"
#include "jailbreak.h"
#include "libproc.h"
#include "rootfs.h"
#include "utils.h"
#include "patchfinder64.h"

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

int jailbreak(void) {
    // OffsetFinder Test Methods
    printf("* ----- Running OffsetFinder ----- *\n");
    // find_kernel_base(g_exp.kernel_base - 0x50);
    // calc_kernel_map(g_exp.kernel_task);
    // TODO: make use of declared methods "OffsetFinder.h"
    printf("* ------- Applying Patches ------- *\n");
    struct proc_cred *old_cred;
    proc_set_root_cred(g_exp.self_proc, &old_cred);
    util_msleep(100);
    int err = setuid(0);
    if (err) perror("setuid");
    patch_TF_PLATFORM(g_exp.self_task);
    uint64_t csflags = read_32(g_exp.self_proc + koffset(KSTRUCT_OFFSET_PROC_CSFLAGS));
    uint64_t csflags_mod = (csflags|0xA8|0x0000008|0x0000004|0x10000000)&~(0x0000800|0x0000100|0x0000200);
    printf("CS Flags:\t0x%llx | 0x%llx\n", csflags, csflags_mod);
    pid_t amfid_pid = look_for_proc_basename("amfid");
    patch_amfid(amfid_pid);
    start_rootfs_remount();
    /*
     *  TODO: AMFI
     *      - allproc, kernproc, ourcreds, spincred, spinents
     *
     */
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
