//
//  ViewController.m
//  reton
//
//  Created by Luca on 15.02.21.
//

#import "ViewController.h"
#include "Exploit/cicuta_virosa.h"
#include "Jailbreak/jailbreak.h"
#include <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_jailbreakButton.layer setBorderColor:[UIColor systemGray2Color].CGColor];
    NSString *programVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [self sendMessageToLog:[NSString stringWithFormat:@"Press 'Jailbreak me' to start (Manticore %@)", programVersion]];
    [self sendMessageToLog:[NSString stringWithFormat:@"@RPwnage && PwnedC99"]];
    // Do any additional setup after loading the view.
}


- (IBAction)runJailbreak:(id)sender {
    [self sendMessageToLog:@"[*] Starting...."];
    self.logWindow.text = @"";
    self.jailbreakButton.enabled = NO;
    int jailbreak_ret = jailbreak(nil);
    if(jailbreak_ret == 0){
        [_jailbreakButton setTitle:@"Jailbroken" forState:UIControlStateNormal];
    }else {
        printf("[Error] Jailbreak function returned %d\n", jailbreak_ret);
    }
}

- (void)sendMessageToLog:(NSString *)Message {
    [self.logWindow insertText:[NSString stringWithFormat:@"%@\n", Message]];
}

@end
