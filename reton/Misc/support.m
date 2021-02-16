//
//  support.m
//  pwner
//
//  Created by Brandon Plank on 10/1/20.
//  Copyright © 2020 GeoSn0w. All rights reserved.
//

#include <Foundation/Foundation.h>
#include "support.h"

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
