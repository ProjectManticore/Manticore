//
//  jailbreak.m
//  reton
//
//  Created by Luca on 15.02.21.
//

#include "../ViewController.h"
#include "../Misc/support.h"
#include "../Misc/kernel_offsets.h"
#include <UIKit/UIKit.h>
#include <sys/sysctl.h>
#include <sys/snapshot.h>
#include <mach/mach.h>
#include <Foundation/Foundation.h>
#include "../Libraries/Bazad/IOSurface.h"
#include "../Libraries/pattern_f/kapi.h"
#include "../Libraries/pattern_f/k_offsets.h"
#include "../Libraries/pattern_f/mycommon.h"
#include "../Exploit/cicuta_virosa.h"
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

int jailbreak(void *init) {
    ViewController *apiController = [UIApplication sharedApplication].keyWindow.rootViewController;
    uint64_t task_pac = 0x0; // cicuta_virosa();

    printf("\n[==================] Discovery v1 [==================]\n");
        
    /* Before PAC ---> After PAC */
    uint64_t task = task_pac|0xffffff8000000000;
    printf("Task:\t\t0x%llx\t--->\t0x%llx\n", task_pac, task);
        
//    uint64_t proc_uid_pac = read_64(task + 0x388 + 0x30);
//    if (!proc_uid_pac) {
//        fprintf(stderr, "failed to get proc_uid\n");
//    } else {
//        uint64_t proc_uid = proc_uid_pac | 0xffffff8000000000;
//        fprintf(stdout, "proc_uid: 0x%llu\n", proc_uid_pac);
//        fprintf(stdout, "proc_uid: 0x%llu\n", proc_uid);
//        fprintf(stdout, "PAC decrypt: 0x%llx -> 0x%llx\n", proc_uid_pac, proc_uid);
//    }
        

    uint64_t proc_pac;
        
    if (SYSTEM_VERSION_LESS_THAN(@"14.0")){
        if(IS_PAC){
            proc_pac = read_64(task + 0x388);
        } else {
            proc_pac = read_64(task + 0x380);
        }
    } else {
        if (IS_PAC){
            proc_pac = read_64(task + 0x3a0);
        } else {
            proc_pac = read_64(task + 0x390);
        }
    }
        
    uint64_t proc = proc_pac | 0xffffff8000000000;
    printf("Proc:\t\t0x%llx\t--->\t0x%llx\n", proc_pac, proc);
        
    uint64_t ucred_pac;
        
    if(SYSTEM_VERSION_LESS_THAN(@"14.0")){
        ucred_pac = read_64(proc + 0x100);
    } else {
        ucred_pac = read_64(proc + 0xf0);
    }
    uint64_t ucred = ucred_pac | 0xffffff8000000000;
    printf("UCRED:\t\t0x%llx\t--->\t0x%llx\n", ucred_pac, ucred);
        
    uint32_t buffer[5] = {0, 0, 0, 1, 0};
    uint64_t old_uid = read_64(ucred + koffset(KSTRUCT_OFFSET_UCRED_CR_UID));
    write_20(ucred + koffset(KSTRUCT_OFFSET_UCRED_CR_UID), (void*)buffer);
    write_20(ucred + koffset(KSTRUCT_OFFSET_PROC_UID), (void*)buffer);
    uint64_t new_uid = read_64(ucred + koffset(KSTRUCT_OFFSET_UCRED_CR_UID));
    uint32_t uid = getuid();
    uint64_t cr_label_pac = read_64(ucred + koffset(KSTRUCT_OFFSET_UCRED_CR_LABEL));
    uint64_t cr_label = cr_label_pac | 0xffffff8000000000;
    printf("CR_Label:\t0x%llx\t--->\t0x%llx\n", cr_label_pac, cr_label);
    printf("[==================] Discovery End [==================]\n");
        
    printf("\n[==================] Patches v1 [==================]\n");
        
    /* Sandbox patches */
    printf("Sandbox-Slot:\t0x%llx", (cr_label + koffset(KSTRUCT_OFFSET_SANDBOX_SLOT)));
    write_20(cr_label + koffset(KSTRUCT_OFFSET_SANDBOX_SLOT), (void*)buffer);
    printf("\t--->\t0x%llx\t\t\t(%s)\n", read_64(cr_label + koffset(KSTRUCT_OFFSET_SANDBOX_SLOT)), check_sandbox_escape() == true ? "success" : "failure");

    /* Root User patches */
    printf("Root-User:\t\t0x%llx\t\t--->\t0x%llx\t\t\t(%s)\n", old_uid, new_uid, uid == 0 ? "success" : "failure");
        
    /* Setting Group ID to 0 */
    uint32_t old_gid = getgid();
    setgid(0);
    uint32_t gid = getgid();
    printf("GroupID:\t\t%u\t\t\t\t\t--->\t%u\t\t\t(%s)\n", old_gid, gid, gid==0 ? "success" : "failure");
    printf("whoami:\t\t\t%s\t\t\t\t\t\t\t\t\t(%s)\n", uid == 0 ? "root" : "mobile", uid == 0 ? "success" : "failure");
        
    /* CS Flags */
    uint64_t csflags = read_32(proc + koffset(KSTRUCT_OFFSET_PROC_CSFLAGS));
    uint64_t csflags_mod = (csflags|0xA8|0x0000008|0x0000004|0x10000000)&~(0x0000800|0x0000100|0x0000200);
    // write_32bits(proc + koffset(KSTRUCT_OFFSET_PROC_CSFLAGS), (void*)csflags_mod);
    printf("CS Flags:\t\t0x%llx\t\t\t--->\t0x%llx\t(%s)\n", csflags, csflags_mod, csflags != csflags_mod ? "success" : "failure");
    
    /* TF_PLATFORM */
    uint64_t t_flags = read_32(task + koffset(KSTRUCT_OFFSET_TASK_TFLAGS));
    uint64_t t_flag_mod = t_flags |= 0x400; // add TF_PLATFORM flag, = 0x400
    // write_32bits(task + koffset(KSTRUCT_OFFSET_TASK_TFLAGS), (void*)t_flag_mod);
    uint64_t csflags_tf = read_32(proc + koffset(KSTRUCT_OFFSET_PROC_CSFLAGS));
    // write_32bits(proc + koffset(KSTRUCT_OFFSET_PROC_CSFLAGS), (void*)(csflags_tf|0x24004001u)); //patch csflags
    printf("TF_PLATFORM:\t0x%llx\t\t\t--->\t0x%llx\t(%s)\n",
           t_flags,
           (uint64_t)read_32(task + koffset(KSTRUCT_OFFSET_TASK_TFLAGS)),
           t_flags != read_32(task + koffset(KSTRUCT_OFFSET_TASK_TFLAGS)) ? "success" : "failure");
    
    
    printf("[==================] Patches End [==================]\n");
    
    printf("\n[==================] KernelPatches [==================]\n");
    
    kern_return_t kr;
    mach_port_t tfp0;
    kr = host_get_special_port(mach_host_self(), HOST_LOCAL_NODE, 4, &tfp0);
    if (!kr && tfp0 == MACH_PORT_NULL) {
        printf("Got cached tfp0:\t0x%x\t\t\t\t\t\t\t\t\t(%s)\n", tfp0, tfp0 == 0 ? "success" : "failure");
        uint64_t kernel_slide = find_kernel_slide(tfp0);
        printf("KernelSlide:\t\t0x%llx\t\t\t\t\t(%s)\n", kernel_slide, kernel_slide != 0 ? "success" : "failure");
        mach_vm_size_t pagesize = get_page_size(tfp0);
        printf("PageSize:\t\t\t0x%llx\t\t\t\t\t\t\t\t(%s)\n", pagesize, pagesize != 0 ? "success" : "failure");
        printf("KernelBase:\t\t\t0x%llx\t\t-->\t\t0x%llx\n", (uint64_t)HARDCODED_kernel_base_addr, HARDCODED_kernel_base_addr - kernel_slide);
        // TODO: fix this function
        // dump_kernel(tfp0, HARDCODED_kernel_base_addr, task);
        // find_kernel_base(proc, tfp0);
        /*
            
            get_all_pids();
            kptr_t next_task = read_64(task + 0x35);
            printf("0x%llx\t->\t0x%llx\n", task, next_task);
            printf("0x%llx\t->\t0x%llx\n", read_64(task), read_64(next_task));
            kptr_t next_task_proc;
            if (IS_PAC){
                next_task_proc = read_64(next_task + 0x3a0);
            } else {
                next_task_proc = read_64(next_task + 0x390);
            }
            printf("OwnPID:\t%d\n", (pid_t)read_64(proc + koffset(KSTRUCT_OFFSET_PROC_PID)));
            printf("Next task PID:\t%d\n", (pid_t)read_64(next_task_proc + koffset(KSTRUCT_OFFSET_PROC_PID)));
         */
        
    } else {
        printf("[-] tfp0 failed\n");
    }
    
    printf("[================] End KernelPatches [================]\n");
    
    printf("\n[==================] Rootfs remount [=================]\n");

    perform_amfid_patches(cr_label);

    /*
     *  TODO: AMFI
     *      - allproc, kernproc, ourcreds, spincred, spinents
     *
     */
        
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
