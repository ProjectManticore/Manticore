//
//  ViewController.h
//  reton
//
//  Created by Luca on 15.02.21.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *jailbreakButton;
@property (weak, nonatomic) IBOutlet UITextView *logWindow;
- (IBAction)runJailbreak:(id)sender;
- (void)sendMessageToLog:(NSString *)Message;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end

