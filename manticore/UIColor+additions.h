//
//  UIColor+additions.h
//  manticore
//
//  Created by Corban Amouzou on 2021-09-04.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef UIColor_utils_h
#define UIColor_utils_h

@interface UIColor (additions)
+ (UIColor *) colorWithHexString:(NSString *)hex;
+ (UIColor *) colorWithHex:(UInt32)color;
+ (NSString *) hexWithColor:(UIColor *)color;
@end

#endif /* UIColor_utils_h */
