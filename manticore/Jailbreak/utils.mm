//
//  utils.m
//  reton
//
//  Created by Luca on 18.02.21.
//

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <mach/error.h>
#include <Security/Security.h>
#include <mach/mach.h>
#include <Security/Security.h>
#include <xnu/bsd/sys/proc_info.h>
#include <xnu/libsyscall/wrappers/libproc/libproc.h>
#include <exploit/cicuta/cicuta_virosa.h>
#include <manticore/kernel_utils.h>
#include <unistd.h>
#include <manticore/utils.h>
#import <spawn.h>

#include <lib/tq/tq_common_p.h>
#include <lib/tq/utils.h>
#include <lib/tq/k_utils.h>
#include <lib/tq/kapi.h>
#include <lib/tq/k_offsets.h>

#include "k_offsets.h"
#include <util/alloc.h>

extern char **environ;
NSData *lastSystemOutput=nil;

int perform_root_patches(kptr_t ucred){
    uint32_t buffer[5] = {0, 0, 0, 1, 0};
    
    /* CR_UID */
    uint64_t old_uid = read_64(ucred + OFFSET(ucred, cr_uid));
    write_20(ucred + OFFSET(ucred, cr_uid), (void*)buffer);
    uint64_t new_uid = read_64(ucred + OFFSET(ucred, cr_uid));
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


void patch_amfid(pid_t amfid_pid){
    printf("* ------ AMFID Bypass ------ *\n");
    kptr_t amfid_kernel_proc = kproc_find_by_pid(amfid_pid);
    printf("amfid proc:\t%d\t->\t0x%llx\n", amfid_pid, amfid_kernel_proc);
    printf("amfid task:\t0x%llx\n", amfid_kernel_proc + OFFSET(proc, task));
    if(setCSFlagsByPID(amfid_pid)){
        printf("Successfully set Amfid's CSFlags.\n");
    } else {
        printf("Unable to set Amfid's csflags.\n");
    }
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

bool patch_TF_PLATFORM(kptr_t task) {
    uint32_t t_flags = 0;
    uint32_t t_flags_mod = 0;
    if(KERN_POINTER_VALID(task)){
        uint32_t t_flags = kapi_read32(task + OFFSET(task, t_flags));
        uint32_t t_flags_mod = t_flags;
        if(g_exp.debug) printf("--> tf_flags:\t%#x |", t_flags);
        t_flags |= 0x00000400;
        kapi_write32(task + OFFSET(task, t_flags), t_flags);
        t_flags_mod = kapi_read32(task + OFFSET(task, t_flags));
        if(g_exp.debug) printf(" %#x\n", t_flags_mod);
        if(t_flags_mod != t_flags || t_flags_mod > 0x00000400) return true;
    } else printf("Can't patch tf_platform of invalid task/kernel_pointer!\n");
    printf("Setting tf_platform failed!\t(%#x <-> %#x)\n", t_flags, t_flags_mod);
    return false;
}


pid_t look_for_proc_internal(const char *name, bool (^match)(const char *path, const char *want)){
    pid_t *pids = (pid_t *)calloc(1, 3000 * sizeof(pid_t));
    int procs_cnt = proc_listpids(PROC_ALL_PIDS, 0, pids, 3000);
    if(procs_cnt > 3000) {
        pids = (pid_t *)realloc(pids, procs_cnt * sizeof(pid_t));
        procs_cnt = proc_listpids(PROC_ALL_PIDS, 0, pids, procs_cnt);
    }
    int len;
    char pathBuffer[4096];
    for (int i=(procs_cnt-1); i>=0; i--) {
        if (pids[i] == 0) {
            continue;
        }
        memset(pathBuffer, 0, sizeof(pathBuffer));
        len = proc_pidpath(pids[i], pathBuffer, sizeof(pathBuffer));
        if (len == 0) {
            continue;
        }
        if (match(pathBuffer, name)) {
            free(pids);
            return pids[i];
        }
    }
    free(pids);
    return 0;
}

pid_t look_for_proc(const char *proc_name){
    return look_for_proc_internal(proc_name, ^bool (const char *path, const char *want) {
        if (!strcmp(path, want)) {
            return true;
        }
        return false;
    });
}

pid_t look_for_proc_basename(const char *base_name){
    return look_for_proc_internal(base_name, ^bool (const char *path, const char *want) {
        const char *base = path;
        const char *last = strrchr(path, '/');
        if (last) {
            base = last + 1;
        }
        if (!strcmp(base, want)) {
            return true;
        }
        return false;
    });
}

void proc_set_root_cred(kptr_t proc, struct proc_cred **old_cred) {
    *old_cred = NULL;
    kptr_t p_ucred = kapi_read_kptr(proc + OFFSET(proc, p_ucred));
    kptr_t cr_posix = p_ucred + OFFSET(ucred, cr_posix);

    size_t cred_size = SIZE(posix_cred);
    char zero_cred[cred_size];
    struct proc_cred *cred_label;
    if(cred_size > sizeof(cred_label->posix_cred)){
        printf("Error:\tstruct proc_cred should be bigger");
        exit(0);
    }
    cred_label = (struct proc_cred *)malloc(sizeof(*cred_label));

    kapi_read(cr_posix, cred_label->posix_cred, cred_size);
    cred_label->cr_label = kapi_read64(cr_posix + SIZE(posix_cred));
    cred_label->sandbox_slot = 0;

    if (cred_label->cr_label) {
        kptr_t cr_label = cred_label->cr_label | 0xffffff8000000000; // untag, 25 bits
        cred_label->sandbox_slot = kapi_read64(cr_label + 0x10);
        kapi_write64(cr_label + 0x10, 0x0);
    }

    memset(zero_cred, 0, cred_size);
    kapi_write(cr_posix, zero_cred, cred_size);
    *old_cred = cred_label;
}

char *get_path_for_pid(pid_t pid) {
    char *ret = NULL;
    uint32_t path_size = PROC_PIDPATHINFO_MAXSIZE;
    char *path = (char *)malloc(path_size);
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


BOOL setCSFlagsByPID(pid_t pid){
    if(!pid) return NO;
    kptr_t proc_proc  = kproc_find_by_pid(pid);
    uint32_t csflags  = kapi_read32(proc_proc + OFFSET(proc, csflags));
    uint32_t newflags = (csflags | 0x4000000 | 0x0000008 | 0x0000004 | 0x10000000) & ~(0x0000800 | 0x0000100 | 0x0000200);
    kapi_write32(proc_proc + OFFSET(proc, csflags), newflags);
    return (kapi_read32(proc_proc + OFFSET(proc, csflags)) == newflags) ? YES : NO;
}


int runCommandv(const char *cmd, int argc, const char * const* argv, void (^unrestrict)(pid_t), bool wait, bool quiet) {
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

    if(quiet != true) printf("%s(%d) command: %s\n", __FUNCTION__, pid, [cmdstr UTF8String]);
    
    if (unrestrict) {
        unrestrict(pid);
        kill(pid, SIGCONT);
    }
    
    if (valid_pipe) {
        close(out_pipe[1]);
    }
    
    if (rv != ERR_SUCCESS) {
        if(quiet != true) printf("%s(%d): ERROR posix_spawn failed (%d): %s\n", __FUNCTION__, pid, rv, strerror(rv));
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
                    if(quiet != true) printf("%s(%d): %s\n", __FUNCTION__, pid, [line UTF8String]);
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
                if(quiet != true) printf("%s(%d): %s\n", __FUNCTION__, pid, [line UTF8String]);
            }
            lastSystemOutput = [outData copy];
        }
        if (waitpid(pid, &rv, 0) == -1) {
            if(quiet != true) printf("ERROR: Waitpid failed\n");
        } else {
            if(quiet != true) printf("%s(%d) completed with exit status %d\n", __FUNCTION__, pid, WEXITSTATUS(rv));
        }
    }
    if (valid_pipe) {
        close(out_pipe[0]);
    }
    return rv;
}

void patch_tf_platform(uint64_t target_task){
    uint32_t old_t_flags = read_32(target_task + OFFSET(task, t_flags));
    old_t_flags |= 0x00000400; // TF_PLATFORM
}

typedef CF_OPTIONS(uint32_t, SecCSFlags) {
    kSecCSDefaultFlags = 0,                    /* no particular flags (default behavior) */
    kSecCSConsiderExpiration = (NSUInteger)1 << 31,        /* consider expired certificates invalid */
};

typedef void *SecStaticCodeRef;
extern "C" OSStatus SecStaticCodeCreateWithPathAndAttributes(CFURLRef path, SecCSFlags flags, CFDictionaryRef attributes, SecStaticCodeRef  _Nullable *staticCode);
extern "C" OSStatus SecCodeCopySigningInformation(SecStaticCodeRef code, SecCSFlags flags, CFDictionaryRef  _Nullable *information);
CFStringRef (*_SecCopyErrorMessageString)(OSStatus status, void * __nullable reserved) = NULL;
enum cdHashType {
    cdHashTypeSHA1 = 1,
    cdHashTypeSHA256 = 2
};

static char *cdHashName[3] = {NULL, "SHA1", "SHA256"};
static enum cdHashType requiredHash = cdHashTypeSHA256;

const void *CFArrayGetValueAtIndex_prevenOverFlow(CFArrayRef theArray, CFIndex idx){
    CFIndex arrCnt = CFArrayGetCount(theArray);
    if(idx >= arrCnt){
        idx = arrCnt - 1;
    }
    return CFArrayGetValueAtIndex(theArray, idx);
}


void *CDHashFor(char *file){

    SecStaticCodeRef staticCode = NULL;
    
    CFStringRef cfstr_path = CFStringCreateWithCString(kCFAllocatorDefault, file, kCFStringEncodingUTF8);
    CFURLRef cfurl = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, cfstr_path, kCFURLPOSIXPathStyle, false);
    CFRelease(cfstr_path);
    OSStatus result = SecStaticCodeCreateWithPathAndAttributes(cfurl, kSecCSDefaultFlags, NULL, &staticCode);
    CFRelease(cfurl);
    if (result != 0) {
        if (_SecCopyErrorMessageString != NULL) {
            CFStringRef error = _SecCopyErrorMessageString(result, NULL);
            
            (printf)("Unable to generate cdhash for %s: %s\n", file, CFStringGetCStringPtr(error, kCFStringEncodingUTF8));
            CFRelease(error);
        } else {
            (printf)("Unable to generate cdhash for %s: %d\n", file, result);
        }
        return nil;
    }
    
    CFDictionaryRef signinginfo;
    result = SecCodeCopySigningInformation(staticCode, kSecCSDefaultFlags, &signinginfo);
    CFRelease(staticCode);
    if (result != 0) {
        (printf)("Unable to copy cdhash info for %s\n", file);
        return NULL;
    }
    
    CFArrayRef cdhashes = (CFArrayRef)CFDictionaryGetValue(signinginfo, CFSTR("cdhashes"));
    CFArrayRef algos = (CFArrayRef)CFDictionaryGetValue(signinginfo, CFSTR("digest-algorithms"));
    int algoIndex = -1;
    CFNumberRef nn = (CFNumberRef)CFArrayGetValueAtIndex_prevenOverFlow(algos, requiredHash);
    if(nn){
        CFNumberGetValue(nn, kCFNumberIntType, &algoIndex);
    }
    
    (printf)("cdhashesCnt: %d\n", CFArrayGetCount(cdhashes));
    (printf)("algosCnt: %d\n", CFArrayGetCount(algos));
    
    CFDataRef cdhash = NULL;
    if (cdhashes == NULL) {
        (printf)("%s: no cdhashes\n", file);
    } else if (algos == NULL) {
        (printf)("%s: no algos\n", file);
    } else if (algoIndex == -1) {
        (printf)("%s: does not have %s hash", cdHashName[requiredHash], file);
    } else {
        cdhash = (CFDataRef)CFArrayGetValueAtIndex_prevenOverFlow(cdhashes, requiredHash);
        if (cdhash == NULL) {
            (printf)("%s: missing %s cdhash entry\n", file, cdHashName[requiredHash]);
        }
    }
    if(cdhash == NULL){
        CFRelease(signinginfo);
        return NULL;
    }
    
    (printf)("cdhash len: %d\n", CFDataGetLength(cdhash));
    char *rv = (char *)calloc(1, 20);
    memcpy(rv, CFDataGetBytePtr(cdhash), 20);
    CFRelease(signinginfo);
    return rv;
}

bool isSymlink(const char *filename) {
    struct stat buf;
    if (lstat(filename, &buf) != ERR_SUCCESS) {
        return false;
    }
    return S_ISLNK(buf.st_mode);
}

bool isDirectory(const char *filename) {
    struct stat buf;
    if (lstat(filename, &buf) != ERR_SUCCESS) {
        return false;
    }
    return S_ISDIR(buf.st_mode);
}

bool isMountpoint(const char *filename) {
    struct stat buf;
    if (lstat(filename, &buf) != ERR_SUCCESS) {
        return false;
    }

    if (!S_ISDIR(buf.st_mode))
        return false;
    
    char *cwd = getcwd(NULL, 0);
    int rv = chdir(filename);
    assert(rv == ERR_SUCCESS);
    struct stat p_buf;
    rv = lstat("..", &p_buf);
    assert(rv == ERR_SUCCESS);
    if (cwd) {
        chdir(cwd);
        SafeFreeNULL(cwd);
    }
    return buf.st_dev != p_buf.st_dev || buf.st_ino == p_buf.st_ino;
}

bool deleteFile(const char *file) {
    NSString *path = @(file);
    if ([[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil]) {
        return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    return YES;
}

bool ensureDirectory(const char *directory, int owner, mode_t mode) {
    NSString *path = @(directory);
    NSFileManager *fm = [NSFileManager defaultManager];
    id attributes = [fm attributesOfItemAtPath:path error:nil];
    if (attributes &&
        [attributes[NSFileType] isEqual:NSFileTypeDirectory] &&
        [attributes[NSFileOwnerAccountID] isEqual:@(owner)] &&
        [attributes[NSFileGroupOwnerAccountID] isEqual:@(owner)] &&
        [attributes[NSFilePosixPermissions] isEqual:@(mode)]
        ) {
        // Directory exists and matches arguments
        return true;
    }
    if (attributes) {
        if ([attributes[NSFileType] isEqual:NSFileTypeDirectory]) {
            // Item exists and is a directory
            return [fm setAttributes:@{
                           NSFileOwnerAccountID: @(owner),
                           NSFileGroupOwnerAccountID: @(owner),
                           NSFilePosixPermissions: @(mode)
                           } ofItemAtPath:path error:nil];
        } else if (![fm removeItemAtPath:path error:nil]) {
            // Item exists and is not a directory but could not be removed
            return false;
        }
    }
    // Item does not exist at this point
    return [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{
                   NSFileOwnerAccountID: @(owner),
                   NSFileGroupOwnerAccountID: @(owner),
                   NSFilePosixPermissions: @(mode)
               } error:nil];
}

bool ensureSymlink(const char *to, const char *from) {
    ssize_t wantedLength = strlen(to);
    ssize_t maxLen = wantedLength + 1;
    char link[maxLen];
    ssize_t linkLength = readlink(from, link, sizeof(link));
    if (linkLength != wantedLength ||
        strncmp(link, to, maxLen) != ERR_SUCCESS
        ) {
        if (!deleteFile(from)) {
            return false;
        }
        if (symlink(to, from) != ERR_SUCCESS) {
            return false;
        }
    }
    return true;
}

bool ensureFile(const char *file, int owner, mode_t mode) {
    NSString *path = @(file);
    NSFileManager *fm = [NSFileManager defaultManager];
    id attributes = [fm attributesOfItemAtPath:path error:nil];
    if (attributes &&
        [attributes[NSFileType] isEqual:NSFileTypeRegular] &&
        [attributes[NSFileOwnerAccountID] isEqual:@(owner)] &&
        [attributes[NSFileGroupOwnerAccountID] isEqual:@(owner)] &&
        [attributes[NSFilePosixPermissions] isEqual:@(mode)]
        ) {
        // File exists and matches arguments
        return true;
    }
    if (attributes) {
        if ([attributes[NSFileType] isEqual:NSFileTypeRegular]) {
            // Item exists and is a file
            return [fm setAttributes:@{
                                       NSFileOwnerAccountID: @(owner),
                                       NSFileGroupOwnerAccountID: @(owner),
                                       NSFilePosixPermissions: @(mode)
                                       } ofItemAtPath:path error:nil];
        } else if (![fm removeItemAtPath:path error:nil]) {
            // Item exists and is not a file but could not be removed
            return false;
        }
    }
    // Item does not exist at this point
    return [fm createFileAtPath:path contents:nil attributes:@{
                               NSFileOwnerAccountID: @(owner),
                               NSFileGroupOwnerAccountID: @(owner),
                               NSFilePosixPermissions: @(mode)
                               }];
}


void jailbreakExistenceCheck(){
    // Check for files that indicate the existence of another jailbreak
    
    // Check for taurine related files
    if(isDirectory("/taurine") && access("/taurine/amfidebilitate.plist", R_OK)){
        printf("-> Spotted taurine files\n");
    }
}

int waitForFile(const char *filename) {
    int rv = access(filename, F_OK);
    for (int i = 0; !(i >= 100 || rv == ERR_SUCCESS); i++) {
        usleep(100000);
        rv = access(filename, F_OK);
    }
    return rv;
}
