//
//  UserInterfacePreferences.m
//  manticore
//
//  Created by Corban Amouzou on 2021-09-04.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UserInterfacePreferences.h"
#import "UIColor+additions.h"

static NSString *kPrefsThemesKey = @"Themes";
static NSString *kPrefsCurrentThemeKey = @"currentTheme";

@implementation Theme

- (Theme *) initFromImport:(NSDictionary<NSString *, id> *)import {
    if (self = [super init]) {
        self.adaptFromSingleColor = import[themeAdaptFromSingleColor]; // possible literal doo doo water here
        self.overrideBackgroundWithColor = import[themeOverrideBackgroundWithColor];
        self.backgroundColor = [UIColor colorWithHexString:import[themeBackgroundColor]];
        self.secondaryBackgroundColor = [UIColor colorWithHexString:import[themeSecondaryBackgroundColor]];
        self.backgroundImagePath = import[themebackgroundImagePath];
        self.rootColor = [UIColor colorWithHexString:import[themeRootColor]];
        self.textColor = [UIColor colorWithHexString:import[themeTextColor]];
        self.accentColor = [UIColor colorWithHexString:import[themeAccentColor]];
        self.name = import[themeName];
    }
    return self;
}

- (NSDictionary<NSString *, id> *) exported {
    return @{
        themeAdaptFromSingleColor: @(self.adaptFromSingleColor),
        themeOverrideBackgroundWithColor: @(self.overrideBackgroundWithColor),
        themeBackgroundColor: [UIColor hexWithColor:self.backgroundColor],
        themeSecondaryBackgroundColor: [UIColor hexWithColor:self.secondaryBackgroundColor],
        themebackgroundImagePath: self.backgroundImagePath,
        themeTextColor: [UIColor hexWithColor:self.textColor],
        themeRootColor: [UIColor hexWithColor:self.rootColor],
        themeAccentColor: [UIColor hexWithColor:self.accentColor],
        themeName: self.name
    };
}

+ (Theme *) defaultTheme {
    return [[Theme alloc] initFromImport:@{
        themeAdaptFromSingleColor: @(false),
        themeOverrideBackgroundWithColor: @(true),
        themeBackgroundColor: [UIColor hexWithColor:UIColor.blackColor],
        themeSecondaryBackgroundColor: [UIColor hexWithColor:UIColor.systemGray6Color],
        themebackgroundImagePath: @"",
        themeTextColor: [UIColor hexWithColor:UIColor.whiteColor],
        themeRootColor: [UIColor hexWithColor:UIColor.clearColor], // Not used here
        themeAccentColor: [UIColor hexWithColor:UIColor.systemIndigoColor],
        themeName: @"default"
    }];
}

+ (Theme *) themeFromName:(NSString *)name {
    NSDictionary<NSString *, id> *data = [[NSUserDefaults standardUserDefaults] valueForKey:kPrefsThemesKey];
    NSDictionary<NSString *, id> *themeData = data[name];
    if (themeData != nil) return [[Theme alloc] initFromImport:themeData];
    assert(NO);
}

@end


@implementation UserInterfacePreferences {
    NSUserDefaults *defaults;
}

- (id) init {
    if (self = [super init]) {
        defaults = [NSUserDefaults standardUserDefaults];
        [defaults registerDefaults:@{
            kPrefsThemesKey: @{
                    @"default": [[Theme defaultTheme] exported]
            },
            kPrefsCurrentThemeKey: @"default"
        }];
        self.currentThemeName = @"default";
    }
    
    return self;
}

+ (UserInterfacePreferences *)shared {
    static UserInterfacePreferences *prefs;
    static dispatch_once_t onceToken;
    
    if (!prefs) {
        dispatch_once(&onceToken, ^{
            prefs = [UserInterfacePreferences new];
        });
    }
    
    return prefs;
}

- (NSString *) getCurrentThemeName {
    return [defaults stringForKey:kPrefsThemesKey];
}

- (void) setCurrentThemeName:(NSString *)currentThemeName {
    if ([Theme themeFromName:currentThemeName] != nil) {
        [defaults setValue:currentThemeName forKey:kPrefsCurrentThemeKey];
        _currentThemeName = currentThemeName;
        _currentTheme = [Theme themeFromName:_currentThemeName];
    }
}

@end
