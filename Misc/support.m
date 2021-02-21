//
//  support.m
//  pwner
//
//  Created by Brandon Plank on 10/1/20.
//  Copyright © 2020 GeoSn0w. All rights reserved.
//

#include <Foundation/Foundation.h>
#include "support.h"
#include "cicuta_log.h"


void LogHandler(int type, const char *fmt) {
    switch (type) {
        case log_info:
            NSLog(@"[+] %s",fmt);
            break;
        case log_error:
            NSLog(@"[Error] %s", fmt);
            break;
        case log_warning:
            NSLog(@"[!] %s", fmt);
            break;
        case log_i:
            NSLog(@"[i] %s", fmt);
        default:
            break;
    }
}

void Log(int type, const char *format, ...) {
    char* string;
    va_list args;
    va_start(args, format);
    if(0 > vasprintf(&string, format, args)) string = NULL;    //this is for logging, so failed allocation is not fatal
    va_end(args);
    if(string) {
        LogHandler(type,string);
        free(string);
    } else {
        LogHandler(type,"Error while logging a message: Memory allocation failed.\n");
    }
}

bool modifyPlist(NSString *filename, void (^function)(id)) {
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data == nil) return false;
    NSPropertyListFormat format = 0;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
    if (plist == nil) return false;
    if (function) function(plist);
    NSData *newData = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:&error];
    if (newData == nil) return false;
    if (![data isEqual:newData]) if (![newData writeToFile:filename atomically:YES]) return false;
    return true;
}

bool createEmptyPlist(NSString *filename){
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
    plist[@"test"] = @"test";
    return [plist writeToFile:filename atomically:YES];
}

NSDictionary *readPlist(NSString *filename){
    NSURL *url = [NSURL fileURLWithPath:filename];
    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    NSDictionary *dictionary = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:&error];
    
    if (!error) return dictionary;
    return 0;
}

NSString *programVersion(){
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

//kptr_t find_vnode_with_fd(kptr_t proc, int fd) {
//    kptr_t ret = KPTR_NULL;
//    _assert(fd > 0);
//    _assert(KERN_POINTER_VALID(proc));
//    kptr_t fdp = read_64(proc + koffset(KSTRUCT_OFFSET_PROC_P_FD));
//    _assert(KERN_POINTER_VALID(fdp));
//    kptr_t ofp = ReadKernel64(fdp + koffset(KSTRUCT_OFFSET_FILEDESC_FD_OFILES));
//    _assert(KERN_POINTER_VALID(ofp));
//    kptr_t fpp = ReadKernel64(ofp + (fd * sizeof(kptr_t)));
//    _assert(KERN_POINTER_VALID(fpp));
//    kptr_t fgp = ReadKernel64(fpp + koffset(KSTRUCT_OFFSET_FILEPROC_F_FGLOB));
//    _assert(KERN_POINTER_VALID(fgp));
//    kptr_t vnode = ReadKernel64(fgp + koffset(KSTRUCT_OFFSET_FILEGLOB_FG_DATA));
//    _assert(KERN_POINTER_VALID(vnode));
//    ret = vnode;
//out:;
//    return ret;
//}
