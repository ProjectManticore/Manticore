//
//  ManticoreViewController.h
//  manticore
//
//  Created by Corban Amouzou on 2021-09-02.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef MainScreenViewController_h
#define MainScreenViewController_h

@interface ManticoreViewController : UIViewController

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *captionLabel;
@property (nonatomic, retain) UIButton *jbButton;
@property (nonatomic, retain) UILabel *jbButtonTitle;
@property (nonatomic, retain) UIView *compatibilityView;
@property (nonatomic, retain) UILabel * compatibilityLabel;
@property (nonatomic, retain) UIViewController *loggingView; // unused
@property (nonatomic, retain) UITextView *backgroundLoggingView;
@property (nonatomic, retain) UILabel *compatibilityTitle;
@property (nonatomic, retain) UIButton *optionsButton;
@property (nonatomic, retain) UILabel *optionsButtonLabel;

@end

#endif /* MainScreenViewController_h */
