//
//  plistutils.m
//  manticore
//
//  Created by ??? on 7/3/21.
//

#import <Foundation/Foundation.h>

/* what the fuck does this do
 * -fugiefire */
bool modifyPlist(NSString *filename, void (^function)(id)) {
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data == nil) return false;
    NSPropertyListFormat format;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
    if (plist == nil) return false;
    if (function) function(plist);
    NSData *newData = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:&error];
    if (newData == nil) return false;
    if (![data isEqual:newData]) if (![newData writeToFile:filename atomically:YES]) return false;
    return true;
}

bool createEmptyPlist(NSString *filename) {
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
    plist[@"test"] = @"test";
    return [plist writeToFile:filename atomically:YES];
}

NSDictionary *readPlist(NSString *filename) {
    NSURL *url = [NSURL fileURLWithPath:filename];
    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    NSDictionary *dictionary = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:&error];
    
    if (!error) return dictionary;
    return 0;
}
