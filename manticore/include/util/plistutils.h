//
//  plistutils.h
//  manticore
//
//  Created by fugiefire on 7/3/21.
//

#ifndef plistutils_h
#define plistutils_h

#import <Foundation/Foundation.h>

/* whoever wrote these, can you add docstrings please? -fugiefire */
bool modifyPlist(NSString *filename, void (^function)(id));
NSDictionary *readPlist(NSString *filename);
bool createEmptyPlist(NSString *filename);

#endif /* plistutils_h */
