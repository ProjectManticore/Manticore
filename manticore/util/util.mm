//
//  util.m
//  manticore
//
//  Created by admin on 7/3/21.
//

#import <Foundation/Foundation.h>

NSString *programVersion() {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}
