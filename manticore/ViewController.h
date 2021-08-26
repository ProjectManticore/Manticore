//
//  ViewController.h
//  reton
//
//  Created by Luca on 15.02.21.
//

#import <UIKit/UIKit.h>
char *Build_resource_path(char *filename);
@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *jailbreakButton;
@property (weak, nonatomic) IBOutlet UIButton *optionsButton;
@property (weak, nonatomic) IBOutlet UITextView *logWindow;
- (IBAction)runJailbreak:(id)sender;
- (IBAction)openOptions:(id)sender;
- (IBAction)setApNonceBtn:(id)sender;
- (void)sendMessageToLog:(NSString *)Message;
bool checkDeviceCompatibility(void);
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *compatibilityLabel;

@end

