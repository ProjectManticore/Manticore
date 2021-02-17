//
//  support.h
//  pwner
//
//  Created by Brandon Plank on 10/1/20.
//  Copyright © 2020 GeoSn0w. All rights reserved.
//

#ifndef support_h
#define support_h

#include <stdio.h>

#define log_info 1
#define log_error 2
#define log_warning 3
#define log_i 4

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

void Log(int type,const char *format, ...) __attribute__ ((format (printf, 2, 3)));
NSString *programVersion(void);

/* Property List Support functions */
bool modifyPlist(NSString *filename, void (^function)(id));
NSDictionary *readPlist(NSString *filename);


#endif /* support_h */
