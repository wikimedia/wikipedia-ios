//  Created by Monte Hurd on 2/21/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "CaptchaViewController.h"
#import "CreateAccountFunnel.h"
#import "FetcherBase.h"

@interface AccountCreationViewController : UIViewController <FetchFinishedDelegate, CaptchaViewControllerRefresh, UITextFieldDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *passwordRepeatField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;

@property (strong, nonatomic) CreateAccountFunnel *funnel;

@property (weak, nonatomic) id truePresentingVC;
@property (weak, nonatomic) TopMenuViewController *topMenuViewController;

@end
