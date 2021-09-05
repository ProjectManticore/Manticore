//
//  UserInterfacePreferences.h
//  manticore
//
//  Created by Corban Amouzou on 2021-09-04.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef UserInterfacePreferences_h
#define UserInterfacePreferences_h

//MARK: Exported Constant Names
static NSString *themeOverrideBackgroundWithColor = @"backgroundColorOverride";
static NSString *themeAdaptFromSingleColor = @"singleColorAdaption";
static NSString *themebackgroundImagePath = @"backgroundImagePath";
static NSString *themeBackgroundColor = @"backgroundColor";
static NSString *themeSecondaryBackgroundColor  = @"secondaryBackgroundColor";
static NSString *themeTextColor = @"textColor";
static NSString *themeRootColor = @"rootColor";
static NSString *themeAccentColor = @"accentColor";
static NSString *themeName = @"name";

@interface Theme: NSObject

@property (nonatomic) BOOL overrideBackgroundWithColor;
@property (nonatomic) BOOL adaptFromSingleColor;
@property (nonatomic, retain) NSString *backgroundImagePath;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *secondaryBackgroundColor;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *rootColor;
@property (nonatomic, retain) UIColor *accentColor;
@property (nonatomic, retain) NSString *name;
// Theme import/export functionality
- (Theme *) initFromImport:(NSDictionary<NSString *, id> *)import;
- (NSDictionary<NSString *, id> *) exported;

@end

@interface UserInterfacePreferences : NSObject
@property (nonatomic) Theme *currentTheme;
@property (nonatomic) NSString *currentThemeName;

+ (instancetype) shared;

@end

#endif /* UserInterfacePreferences_h */
