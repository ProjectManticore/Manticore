//
//  JailbreakPreferences.m
//  manticore
//
//  Created by Corban Amouzou on 2021-09-04.
//

#import <Foundation/Foundation.h>
#import "JailbreakPreferences.h"


@implementation JailbreakPreferences {
    NSUserDefaults *defaults;
}

@dynamic restoreRootFS;
@dynamic disableUpdates;
@dynamic maxMemLimit;
@dynamic loadTweaks;
@dynamic loadDaemons;
@dynamic showLogWindow;
@dynamic disableScreenTime;
@dynamic selectedPackageManager;

- (id) init {
    if (self = [super init]) {
        defaults = [NSUserDefaults standardUserDefaults];
        [defaults registerDefaults:@{
            jbPrefsSelectedPackageManager: @(Cydia),
            jbPrefsRestoreRootFS: @(NO),
            jbPrefsDisableUpdates: @(YES),
            jbPrefsMaxMemLimit: @(NO),
            jbPrefsLoadTweaks: @(YES),
            jbPrefsLoadDaemons: @(YES),
            jbPrefsShowLogWindow: @(YES),
            jbPrefsDisableScreenTime: @(NO),
        }];
    }
    return self;
}

+ (instancetype) shared {
    static JailbreakPreferences *jbPrefs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        jbPrefs = [JailbreakPreferences new];
    });
    
    return jbPrefs;
}

- (NSDictionary<NSString *, id> *) dictionaryRepresentation {
    return  @{
        
    };
}

- (BOOL) restoreRootFS {
    return [defaults boolForKey:jbPrefsRestoreRootFS];
}

- (void) setRestoreRootFS:(BOOL)restoreRootFS {
    [defaults setBool:restoreRootFS forKey:jbPrefsRestoreRootFS];
}

- (BOOL) disableUpdates {
    return [defaults boolForKey:jbPrefsDisableUpdates];
}

- (void) setDisableUpdates:(BOOL)disableUpdates {
    [defaults setBool:disableUpdates forKey:jbPrefsDisableUpdates];
}

- (BOOL) maxMemLimit {
    return [defaults boolForKey:jbPrefsMaxMemLimit];
}

- (void) setMaxMemLimit:(BOOL)maxMemLimit {
    [defaults setBool:maxMemLimit forKey:jbPrefsMaxMemLimit];
}

- (BOOL) loadTweaks {
    return [defaults boolForKey:jbPrefsLoadTweaks];
}

- (void) setLoadTweaks:(BOOL)loadTweaks {
    [defaults setBool:loadTweaks forKey:jbPrefsLoadTweaks];
}

- (BOOL) loadDaemons {
    return [defaults boolForKey:jbPrefsLoadDaemons];
}

- (void) setLoadDaemons:(BOOL)loadDaemons {
    [defaults setBool:loadDaemons forKey:jbPrefsLoadDaemons];
}

- (BOOL) showLogWindow {
    return [defaults boolForKey:jbPrefsShowLogWindow];
}

- (void) setShowLogWindow:(BOOL)showLogWindow {
    [defaults setBool:showLogWindow forKey:jbPrefsShowLogWindow];
}

- (BOOL) disableScreenTime {
    return [defaults boolForKey:jbPrefsDisableScreenTime];
}

- (void) setDisableScreenTime:(BOOL)disableScreenTime {
    [defaults setBool:disableScreenTime forKey:jbPrefsDisableScreenTime];
}

- (PackageManager) selectedPackageManager {
    return [defaults integerForKey:jbPrefsSelectedPackageManager];
}

- (void) setSelectedPackageManager:(PackageManager)selectedPackageManager {
    [defaults setInteger:selectedPackageManager forKey:jbPrefsSelectedPackageManager];  
}
@end
