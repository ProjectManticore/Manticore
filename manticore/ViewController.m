//
//  ViewController.m
//  reton
//
//  Created by GeoSn0w on 24.08.21.
//

#import "ViewController.h"
#include <exploit/cicuta/cicuta_virosa.h> // cicuta_virosa exploit [14.0 --> 14.3]
#include <manticore/jailbreak.h>
#include <exploit/cicuta/exploit_main.h>
#include <objc/runtime.h>

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

NSString *APNonce = NULL;

@interface ViewController ()

@end

@implementation ViewController

bool checkDeviceCompatibility(){
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [_jailbreakButton.layer setBorderColor:[UIColor systemGray2Color].CGColor];
    NSString *programVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    handleExistingJailbreak(self);
    
    if (checkDeviceCompatibility()) {
        _compatibilityLabel.text = [NSString stringWithFormat:@"Your %@ on iOS %@ is compatible with manticore!", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]];
    } else {
        _compatibilityLabel.text = [NSString stringWithFormat:@"Your %@ on iOS %@ is NOT compatible with Manticore.", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]];
        self.jailbreakButton.enabled = NO;
        [_jailbreakButton setTitle:@"Incompatible" forState:UIControlStateDisabled];
    }
    
    [self sendMessageToLog:[NSString stringWithFormat:@"Press 'Jailbreak Me' to start (Manticore %@)", programVersion]];
    
    [self sendMessageToLog:[NSString stringWithFormat:@"@RPwnage && PwnedC99"]];
    
    // Do any additional setup after loading the view.
}


- (IBAction)runJailbreak:(id)sender {
    [self sendMessageToLog:@"[*] Starting...."];
    
    self.logWindow.text = @"";
    self.jailbreakButton.enabled = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync( dispatch_get_main_queue(), ^{
            exploit_main();
        });
    });
}

- (void)sendMessageToLog:(NSString *)Message {
    [self.logWindow insertText:[NSString stringWithFormat:@"%@\n", Message]];
}

char *anotherJailbreakMessage;
void handleExistingJailbreak(id selfless) {
    NSString *jailbreakName = [NSString stringWithUTF8String:anotherJailbreakMessage];
    NSString *messageForUser = [NSString stringWithFormat:@"%s/%@/%@", "We've detected you have ", jailbreakName, @"already installed. Please uninstall it first, and restore ROOT FS before jailbreaking with Manticore to prevent any compatibility issues."];
    
    UIAlertController *existingJailbreakAlert = [UIAlertController alertControllerWithTitle:@"Critical Error" message:messageForUser preferredStyle:UIAlertControllerStyleAlert];

    [selfless presentViewController:existingJailbreakAlert animated:YES completion:nil];
}

- (IBAction)openOptions:(id)sender {
    
}

@end
