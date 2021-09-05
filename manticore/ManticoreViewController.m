//
//  ManticoreViewController.m
//  manticore
//
//  Created by Corban Amouzou on 2021-09-02.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <exploit/cicuta/cicuta_virosa.h> // cicuta_virosa exploit [14.0 --> 14.3]
#import <manticore/jailbreak.h>
#import <util.h>
#import <exploit/cicuta/exploit_main.h>
#import <objc/runtime.h>
#import "ManticoreViewController.h"
#import "ManticoreOptionsTableViewController.h"
#import "UserInterfacePreferences.h"

#define SCREEN_WIDTH UIScreen.mainScreen.bounds.size.width
#define SCREEN_HEIGHT UIScreen.mainScreen.bounds.size.height
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


bool checkDeviceCompatibility() {
    // proper range check so that iOS 14.7.1 wouldn't say it's compatible when we use cicuta_virosa
    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"14.3") && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"14.0")){
        NSLog(@"[+] Found compatible device, continuing...");
        return true;
    } else {
        NSLog(@"[!] Incompatible device detected. Will not continue.");
        return false;
    }
}

char *Build_resource_path(char *filename){
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    if(filename == NULL) {
        return strdup([[resourcePath stringByAppendingString:@"/"] UTF8String]);
    }
    return strdup([[resourcePath stringByAppendingPathComponent:[NSString stringWithUTF8String:filename]] UTF8String]);
}

@implementation ManticoreViewController {
    UserInterfacePreferences *_prefs;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    _prefs = [UserInterfacePreferences shared];
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.view.backgroundColor = UIColor.blackColor; // Temporary
    self.backgroundLoggingView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    
    self.titleLabel = [UILabel new];
    self.captionLabel = [UILabel new];
    self.jbButton = [UIButton new];
    self.compatibilityView = [UIView new];
    self.compatibilityLabel = [UILabel new];
    self.compatibilityTitle = [UILabel new];
    self.jbButtonTitle = [UILabel new];
    self.optionsButton = [UIButton new];
    self.optionsButtonLabel = [UILabel new];
    
    [self.view addSubview:self.backgroundLoggingView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.captionLabel];
    [self.view addSubview:self.jbButton];
    [self.view addSubview:self.jbButtonTitle];
    [self.view addSubview:self.compatibilityView];
    [self.view addSubview:self.compatibilityLabel];
    [self.view addSubview:self.compatibilityTitle];
    [self.view addSubview:self.optionsButton];
    [self.view addSubview:self.optionsButtonLabel];
    
    for (UIView *view in self.view.subviews) {
        view.translatesAutoresizingMaskIntoConstraints = false;
    }
    
    [self setPortraitConstraints];
    
    self.backgroundLoggingView.editable = false;
    self.backgroundLoggingView.selectable = true;
    self.backgroundLoggingView.textColor = UIColor.systemGray2Color;
    self.backgroundLoggingView.font = [UIFont fontWithName:@"Menlo Regular" size:11];
    self.backgroundLoggingView.text = [NSString stringWithFormat:@"[*] Manticore Version %@\n[*] %@ %@ %@\n[*] Testing active, jailbreak may be unstable \n[*] (version unsupported)",
                                       [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                                       UIDevice.currentDevice.localizedModel,
                                       UIDevice.currentDevice.systemName,
                                       UIDevice.currentDevice.systemVersion];
    self.backgroundLoggingView.gestureRecognizers = nil;
    
    
    self.titleLabel.text = @"Manticore";
    self.titleLabel.font = [UIFont systemFontOfSize:50 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = _prefs.currentTheme.textColor;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.captionLabel.text = @"iOS 14.0 - 14.3";
    self.captionLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightLight];
    self.captionLabel.textColor = _prefs.currentTheme.textColor;
    self.captionLabel.textAlignment = NSTextAlignmentCenter;

    
    [self.jbButton addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        self.jbButton.enabled = NO;
        [self runJailbreak];
    }] forControlEvents:UIControlEventTouchUpInside];
    self.jbButton.backgroundColor =  _prefs.currentTheme.secondaryBackgroundColor;
    self.jbButton.layer.cornerRadius = 15;
    self.jbButton.layer.borderColor = [_prefs.currentTheme.textColor colorWithAlphaComponent:0.7].CGColor;
    self.jbButton.layer.borderWidth = 1;
    self.jbButton.clipsToBounds = YES;
    
    
    self.jbButtonTitle.font = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    self.jbButtonTitle.textColor = _prefs.currentTheme.textColor;
    self.jbButtonTitle.textAlignment = NSTextAlignmentCenter;
    self.jbButtonTitle.text = @"Jailbreak";
    

    self.compatibilityView.backgroundColor = _prefs.currentTheme.secondaryBackgroundColor;
    self.compatibilityView.layer.cornerRadius = 20;
    self.compatibilityView.clipsToBounds = true;
    
    
    self.compatibilityLabel.textAlignment = NSTextAlignmentCenter;
    self.compatibilityLabel.text = [NSString stringWithFormat:@"Your device on iOS %@ is%s \ncompatible with Manticore", UIDevice.currentDevice.systemVersion, checkDeviceCompatibility() ? "" : " NOT"];
    self.compatibilityLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.compatibilityLabel.numberOfLines = 0;
    [self.compatibilityLabel sizeToFit];
    
    self.compatibilityTitle.textAlignment = NSTextAlignmentCenter;
    self.compatibilityTitle.text = @"Compatability";
    self.compatibilityTitle.textColor = _prefs.currentTheme.textColor;
    self.compatibilityTitle.font = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    
    self.optionsButton.backgroundColor = [_prefs.currentTheme.secondaryBackgroundColor initWithWhite:0.05 alpha:1.0];
    self.optionsButton.layer.cornerRadius = 20;
    
    [self.optionsButton addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [self updateLog:@"Options Opened"];
        ManticoreOptionsTableViewController *viewController = [[ManticoreOptionsTableViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
        viewController.providesPresentationContextTransitionStyle = true;
        viewController.definesPresentationContext = true;
        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:viewController animated:YES completion:^{}];
    }] forControlEvents:UIControlEventTouchUpInside];
    
    self.optionsButtonLabel.textColor = _prefs.currentTheme.textColor;
    self.optionsButtonLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    self.optionsButtonLabel.text = @"Options";

}

- (void) setPortraitConstraints {
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.widthAnchor constraintEqualToConstant:250],
        [self.titleLabel.heightAnchor constraintEqualToConstant:60],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:45 + self.view.safeAreaInsets.top]
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.captionLabel.widthAnchor constraintEqualToConstant:200],
        [self.captionLabel.heightAnchor constraintEqualToConstant:30],
        [self.captionLabel.centerXAnchor constraintEqualToAnchor:self.titleLabel.centerXAnchor],
        [self.captionLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:5]
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.jbButton.widthAnchor constraintEqualToConstant:180],
        [self.jbButton.heightAnchor constraintEqualToConstant:60],
        [self.jbButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.jbButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-10]
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.jbButtonTitle.widthAnchor constraintEqualToConstant:100],
        [self.jbButtonTitle.heightAnchor constraintEqualToConstant:20],
        [self.jbButtonTitle.centerXAnchor constraintEqualToAnchor:self.jbButton.centerXAnchor],
        [self.jbButtonTitle.centerYAnchor constraintEqualToAnchor:self.jbButton.centerYAnchor]
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.compatibilityView.widthAnchor constraintEqualToConstant:300],
        [self.compatibilityView.heightAnchor constraintEqualToConstant:120],
        [self.compatibilityView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.compatibilityView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-80]
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.compatibilityTitle.widthAnchor constraintEqualToConstant:150],
        [self.compatibilityTitle.heightAnchor constraintEqualToConstant:30],
        [self.compatibilityTitle.centerXAnchor constraintEqualToAnchor:self.compatibilityView.centerXAnchor],
        [self.compatibilityTitle.topAnchor constraintEqualToAnchor:self.compatibilityView.topAnchor constant:15]
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.compatibilityLabel.widthAnchor constraintEqualToConstant:250],
        [self.compatibilityLabel.heightAnchor constraintEqualToConstant:60],
        [self.compatibilityLabel.centerXAnchor constraintEqualToAnchor:self.compatibilityView.centerXAnchor],
        [self.compatibilityLabel.topAnchor constraintEqualToAnchor:self.compatibilityTitle.bottomAnchor constant:5]
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.optionsButton.widthAnchor constraintEqualToConstant:300],
        [self.optionsButton.heightAnchor constraintEqualToConstant:120],
        [self.optionsButton.centerYAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.optionsButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.optionsButtonLabel.topAnchor constraintEqualToAnchor:self.optionsButton.topAnchor constant:10],
        [self.optionsButtonLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
    ]];
    
}



- (void) runJailbreak {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync( dispatch_get_main_queue(), ^{
            exploit_main();
        });
    });
}

- (void) updateLog:(NSString *)log {
    [self.backgroundLoggingView insertText:[NSString stringWithFormat:@"\n[*] %@", log]];
    NSRange bottom = NSMakeRange(self.backgroundLoggingView.text.length - 1, 1);
    [self.backgroundLoggingView scrollRangeToVisible:bottom];
}

char *anotherJailbreakMessage;
void handleExistingJailbreak(id selfless) {
    NSString *jailbreakName = anotherJailbreakMessage ? [NSString stringWithUTF8String: anotherJailbreakMessage]: nil;
    NSString *messageForUser = [NSString stringWithFormat:@"%s/%@/%@", "We've detected you have ", jailbreakName, @"already installed. Please uninstall it first, and restore ROOT FS before jailbreaking with Manticore to prevent any compatibility issues."];
    
    UIAlertController *existingJailbreakAlert = [UIAlertController alertControllerWithTitle:@"Critical Error" message:messageForUser preferredStyle:UIAlertControllerStyleAlert];

    [selfless presentViewController:existingJailbreakAlert animated:YES completion:nil];
}


- (bool) prefersStatusBarHidden {
    return true;
}

@end
