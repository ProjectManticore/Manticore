//
//  utils.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include <mach/error.h>
#include "../Libraries/System/sys/proc_info.h"
#include "../Libraries/System/libproc.h"
#include "../Misc/support.h"
#include "../Exploit/cicuta_virosa.h"
#include "../Misc/kernel_offsets.h"
#include "kernel_utils.h"
#include "utils.h"
#import <spawn.h>

extern char **environ;
NSData *lastSystemOutput=nil;

int perform_root_patches(kptr_t ucred){
    uint32_t buffer[5] = {0, 0, 0, 1, 0};
    
    /* CR_UID */
    uint64_t old_uid = read_64(ucred + KSTRUCT_OFFSET_UCRED_CR_UID);
    write_20(ucred + KSTRUCT_OFFSET_UCRED_CR_UID, (void*)buffer);
    uint64_t new_uid = read_64(ucred + KSTRUCT_OFFSET_UCRED_CR_UID);
    if(old_uid == new_uid) return 1;
//
//    /* CR_RUID */
//    uint64_t old_ruid = read_64(ucred + KSTRUCT_OFFSET_UCRED_CR_RUID);
//    write_20(ucred + KSTRUCT_OFFSET_UCRED_CR_RUID, (void*)buffer);
//    uint64_t new_ruid = read_64(ucred + KSTRUCT_OFFSET_UCRED_CR_RUID);
//    if(old_ruid == new_ruid) return 1;
//
//    /* CR_SVGID */
//    uint64_t old_svgid = read_64(ucred + KSTRUCT_OFFSET_UCRED_CR_SVGID);
//    write_20(ucred + KSTRUCT_OFFSET_UCRED_CR_SVGID, (void*)buffer);
//    uint64_t new_svgid = read_64(ucred + KSTRUCT_OFFSET_UCRED_CR_SVGID);
//    if(old_svgid == new_svgid) return 1;
//
//    /* CR_SVUID */
//    uint64_t old_svuid = read_64(ucred + KSTRUCT_OFFSET_UCRED_CR_SVUID);
//    write_20(ucred + KSTRUCT_OFFSET_UCRED_CR_SVUID, (void*)buffer);
//    uint64_t new_svuid = read_64(ucred + KSTRUCT_OFFSET_UCRED_CR_SVUID);
//    if(old_svuid == new_svuid) return 1;
    
    
    
    return 0;
}

bool set_csflags(kptr_t proc, uint32_t flags, bool value) {
    bool ret = false;
    if(!KERN_POINTER_VALID(proc)) return 0;
    kptr_t proc_csflags_addr = proc + 0x280;
    uint32_t csflags = read_32(proc_csflags_addr);
    if (value == true) {
        csflags |= flags;
    } else {
        csflags &= ~flags;
    }
  //  write_32(proc_csflags_addr, (void*)csflags);
    ret = true;
    return ret;
}

bool set_cs_platform_binary(kptr_t proc, bool value) {
    bool ret = false;
    if(!KERN_POINTER_VALID(proc)) return 0;
    if(!set_csflags(proc, 0x4000000, value)) return 0;
    ret = true;
    return ret;
}

char *get_path_for_pid(pid_t pid) {
    char *ret = NULL;
    uint32_t path_size = PROC_PIDPATHINFO_MAXSIZE;
    char *path = malloc(path_size);
    if (path != NULL) {
        if (proc_pidpath(pid, path, path_size) >= 0) {
            ret = strdup(path);
        }
        SafeFreeNULL(path);
    }
    return ret;
}

pid_t pid_of_process(const char *name) {
    char real[PROC_PIDPATHINFO_MAXSIZE];
    bzero(real, sizeof(real));
    realpath(name, real);
    int numberOfProcesses = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    pid_t pids[numberOfProcesses];
    bzero(pids, sizeof(pids));
    proc_listpids(PROC_ALL_PIDS, 0, pids, (int)sizeof(pids));
    bool foundProcess = false;
    pid_t processPid = 0;
    for (int i = 0; i < numberOfProcesses && !foundProcess; ++i) {
        if (pids[i] == 0) {
            continue;
        }
        char *path = get_path_for_pid(pids[i]);
        if (path != NULL) {
            if (strlen(path) > 0 && strcmp(path, real) == 0) {
                processPid = pids[i];
                foundProcess = true;
            }
            SafeFreeNULL(path);
        }
    }
    return processPid;
}

bool restartSpringBoard(void) {
    pid_t backboardd_pid = pid_of_process("/usr/libexec/backboardd");
    if (!(backboardd_pid > 1)) {
        printf("Unable to find backboardd pid.\n");
        return false;
    }
    if (kill(backboardd_pid, SIGTERM) != ERR_SUCCESS) {
        printf("Unable to terminate backboardd.\n");
        return false;
    }
    return true;
}

int runCommand(const char *cmd, ...) {
    va_list ap, ap2;
    int argc = 1;

    va_start(ap, cmd);
    va_copy(ap2, ap);

    while (va_arg(ap, const char *) != NULL) {
        argc++;
    }
    va_end(ap);
    
    const char *argv[argc+1];
    argv[0] = cmd;
    for (int i=1; i<argc; i++) {
        argv[i] = va_arg(ap2, const char *);
    }
    va_end(ap2);
    argv[argc] = NULL;

    void (^unrestrict)(pid_t pid) = NULL;
    unrestrict = ^(pid_t pid) {
        kptr_t proc = get_proc_struct_for_pid(pid);
        set_platform_binary(proc, true);
        set_cs_platform_binary(proc, true);
    };
    int rv = runCommandv(cmd, argc, argv, unrestrict, true);
    return WEXITSTATUS(rv);
}

int runCommandv(const char *cmd, int argc, const char * const* argv, void (^unrestrict)(pid_t), bool wait) {
    pid_t pid;
    posix_spawn_file_actions_t *actions = NULL;
    posix_spawn_file_actions_t actionsStruct;
    int out_pipe[2];
    bool valid_pipe = false;
    posix_spawnattr_t *attr = NULL;
    posix_spawnattr_t attrStruct;
    
    NSMutableString *cmdstr = [NSMutableString stringWithCString:cmd encoding:NSUTF8StringEncoding];
    for (int i=1; i<argc; i++) {
        [cmdstr appendFormat:@" \"%s\"", argv[i]];
    }

    valid_pipe = pipe(out_pipe) == ERR_SUCCESS;
    if (valid_pipe && posix_spawn_file_actions_init(&actionsStruct) == ERR_SUCCESS) {
        actions = &actionsStruct;
        posix_spawn_file_actions_adddup2(actions, out_pipe[1], 1);
        posix_spawn_file_actions_adddup2(actions, out_pipe[1], 2);
        posix_spawn_file_actions_addclose(actions, out_pipe[0]);
        posix_spawn_file_actions_addclose(actions, out_pipe[1]);
    }
    
    if (unrestrict && posix_spawnattr_init(&attrStruct) == ERR_SUCCESS) {
        attr = &attrStruct;
        posix_spawnattr_setflags(attr, POSIX_SPAWN_START_SUSPENDED);
    }
    
    char *dt_mode = getenv("OS_ACTIVITY_DT_MODE");
    if (dt_mode) {
        dt_mode = strdup(dt_mode); // I didn't check for failure because that will just permanently unset DT_MODE
        unsetenv("OS_ACTIVITY_DT_MODE"); // This causes all NSLog entries go to STDERR and breaks firmware.sh
    }
    

    int rv = posix_spawn(&pid, cmd, actions, attr, (char *const *)argv, environ);

    if (dt_mode) {
        setenv("OS_ACTIVITY_DT_MODE", dt_mode, 1);
        free(dt_mode);
    }

    printf("%s(%d) command: %s\n", __FUNCTION__, pid, [cmdstr UTF8String]);
    
    if (unrestrict) {
        unrestrict(pid);
        kill(pid, SIGCONT);
    }
    
    if (valid_pipe) {
        close(out_pipe[1]);
    }
    
    if (rv != ERR_SUCCESS) {
        printf("%s(%d): ERROR posix_spawn failed (%d): %s\n", __FUNCTION__, pid, rv, strerror(rv));
        rv <<= 8; // Put error into WEXITSTATUS
    } else if (wait) {
        if (valid_pipe) {
            NSMutableData *outData = [NSMutableData new];
            char c;
            char s[2] = {0, 0};
            NSMutableString *line = [NSMutableString new];
            while (read(out_pipe[0], &c, 1) == 1) {
                [outData appendBytes:&c length:1];
                if (c == '\n') {
                    printf("%s(%d): %s\n", __FUNCTION__, pid, [line UTF8String]);
                    [line setString:@""];
                } else {
                    s[0] = c;
                    NSString *str = @(s);
                    if (str == nil)
                        continue;
                    [line appendString:str];
                }
            }
            if ([line length] > 0) {
                printf("%s(%d): %s\n", __FUNCTION__, pid, [line UTF8String]);
            }
            lastSystemOutput = [outData copy];
        }
        if (waitpid(pid, &rv, 0) == -1) {
            printf("ERROR: Waitpid failed\n");
        } else {
            printf("%s(%d) completed with exit status %d\n", __FUNCTION__, pid, WEXITSTATUS(rv));
        }
    }
    if (valid_pipe) {
        close(out_pipe[0]);
    }
    return rv;
}
