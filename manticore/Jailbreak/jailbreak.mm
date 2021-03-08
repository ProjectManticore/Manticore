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
#include "offset_finder/kernel_offsets.h"
#include "offset_finder.h"
#include "manticore/amfid.h"
#include "manticore/hsp4.h"
#include "manticore/kernel_utils.h"
#include "manticore/jailbreak.h"
#include "manticore/rootfs.h"
#include "manticore/utils.h"

#include "util/plistutils.h"

#include "xnu/libsyscall/wrappers/libproc/libproc.h"


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
    // OffsetFinder Test Methods
    printf("* ----- Running OffsetFinder ----- *\n");
    printf("Kernel_task:\t0x%llx\n", g_exp.kernel_task);
    printf("Kernel_base:\t0x%llx\n", g_exp.kernel_base);
    kptr_t kernel_cred_addr = get_kernel_cred_addr(g_exp.kernel_proc);
    printf("Kernel_cred:\t0x%llx\n", kernel_cred_addr);
    kptr_t kernel_vm_map = get_kernel_vm_map(g_exp.kernel_task);
    printf("Kernel_vm_map:\t0x%llx\n", kernel_vm_map);
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
    

    
    // AMFID PATCHES
    perform_amfid_patches();
    // start_rootfs_remount();
    //    init_offset_finder(g_exp.kernel_base);
    //    kptr_t kern_calced_task = find_kernel_task(&g_exp.kernel_base, 0x0000000003000000);
    //    printf("Calculated Kernel Task: 0x%llx\n", kern_calced_task);
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
