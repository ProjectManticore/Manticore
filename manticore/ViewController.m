//
//  ViewController.m
//  reton
//
//  Created by Luca on 15.02.21.
//

#import "ViewController.h"
#include <exploit/cicuta/cicuta_virosa.h>
#include <exploit/cicuta/exploit_main.h>
#include <manticore/jailbreak.h>
#include <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_jailbreakButton.layer setBorderColor:[UIColor systemGray2Color].CGColor];
    NSString *programVersion =
        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    // TODO
    //  checkCompatibility();
    _compatibilityLabel.text = [NSString
        stringWithFormat:@"Your %@ on iOS %@ is compatible with manticore!",
                         [[UIDevice currentDevice] model],
                         [[UIDevice currentDevice] systemVersion]];
    [self
        sendMessageToLog:[NSString stringWithFormat:@"Press 'Jailbreak me' to "
                                                    @"start (Manticore %@)",
                                                    programVersion]];
    [self sendMessageToLog:[NSString stringWithFormat:@"@RPwnage && PwnedC99"]];
    // Do any additional setup after loading the view.
}

- (IBAction)runJailbreak:(id)sender {
    [self sendMessageToLog:@"[*] Starting...."];
    self.logWindow.text = @"";
    self.jailbreakButton.enabled = NO;
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          dispatch_sync(dispatch_get_main_queue(), ^{
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
