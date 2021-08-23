//
//  ViewController.m
//  reton
//
//  Created by Luca on 15.02.21.
//

#import "ViewController.h"
#include <exploit/cicuta/cicuta_virosa.h>
#include <manticore/jailbreak.h>
#include <exploit/cicuta/exploit_main.h>
#include <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

char *Build_resource_path(char *filename){
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    if(filename == NULL) {
        return strdup([[resourcePath stringByAppendingString:@"/"] UTF8String]);
    }
    return strdup([[resourcePath stringByAppendingPathComponent:[NSString stringWithUTF8String:filename]] UTF8String]);
}

- (BOOL)checkCompatibility {
    NSArray *osVersion = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];

    if ([[osVersion objectAtIndex:0] doubleValue] >= 14.3 || [[osVersion objectAtIndex:0] doubleValue] < 14.0) {
        return false; // Device version either greater than 14.3, or less than 14.0
    }
    return true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_jailbreakButton.layer setBorderColor:[UIColor systemGray2Color].CGColor];
    NSString *programVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    // TODO: Finish checkCompatibility method.
    
    BOOL compatible = [self checkCompatibility];
    
    if (compatible) {
        _compatibilityLabel.text = [NSString stringWithFormat:@"Your %@ on iOS %@ is compatible with manticore!", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]];
    } else {
        _compatibilityLabel.text = [NSString stringWithFormat:@"Your %@ on iOS %@ is NOT compatible with Manticore.", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]];
    }
    
    [self sendMessageToLog:[NSString stringWithFormat:@"Press 'Jailbreak me' to start (Manticore %@)", programVersion]];
    
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

- (IBAction)openOptions:(id)sender {
    
}

@end
