//  Created by Monte Hurd on 2/21/14.

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"
#import "CaptchaViewController.h"

@interface AccountCreationViewController : UIViewController <NetworkOpDelegate, CaptchaViewControllerRefresh, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *passwordRepeatField;
@property (weak, nonatomic) IBOutlet UITextField *realnameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;

@end
