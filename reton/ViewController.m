//
//  ViewController.m
//  reton
//
//  Created by Luca on 15.02.21.
//

#import "ViewController.h"
#include "cicuta_virosa.h"
#include "jailbreak.h"
#include <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *programVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [self sendMessageToLog:@"Press 'Jailbreak me' to start"];
    // Do any additional setup after loading the view.
}


- (IBAction)runJailbreak:(id)sender {
    [self sendMessageToLog:@"[*] Starting...."];
    self.logWindow.text = @"";
    self.jailbreakButton.enabled = NO;
    if(jailbreak(nil) == 0){
        self.jailbreakButton.titleLabel.text = @"Jailbroken";
    }
}

- (void)sendMessageToLog:(NSString *)Message {
    [self.logWindow insertText:[NSString stringWithFormat:@"\n%@", Message]];
}

@end
