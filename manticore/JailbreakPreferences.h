//
//  JailbreakPreferences.h
//  manticore
//
//  Created by Corban Amouzou on 2021-09-04.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef JailbreakPreferences_h
#define JailbreakPreferences_h

typedef NS_ENUM(NSInteger, PackageManager) {
    Cydia,
    Sileo,
    Zebra,
    Installer
};

static NSString *jbPrefsRestoreRootFS = @"restoreRootFS";
static NSString *jbPrefsDisableUpdates = @"disableUpdates";
static NSString *jbPrefsMaxMemLimit = @"maxOutMemory";
static NSString *jbPrefsLoadTweaks = @"loadTweaks";
static NSString *jbPrefsLoadDaemons = @"loadDaemons";
static NSString *jbPrefsShowLogWindow = @"showLogWindow";
static NSString *jbPrefsDisableScreenTime = @"disableScreenTime";
static NSString *jbPrefsSelectedPackageManager = @"currentPackageManagerToInstall";

@interface JailbreakPreferences: NSObject

@property (nonatomic) BOOL restoreRootFS;
@property (nonatomic) BOOL disableUpdates;
@property (nonatomic) BOOL maxMemLimit;
@property (nonatomic) BOOL loadTweaks;
@property (nonatomic) BOOL loadDaemons;
@property (nonatomic) BOOL showLogWindow;
@property (nonatomic) BOOL disableScreenTime;
@property (nonatomic) PackageManager selectedPackageManager;

+ (instancetype) shared;
- (NSDictionary<NSString *, id> *) dictionaryRepresentation;

@end

#endif /* JailbreakPreferences_h */
