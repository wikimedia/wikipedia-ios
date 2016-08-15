#import <UIKit/UIKit.h>
#import "CaptchaViewController.h"
#import "CreateAccountFunnel.h"

@interface AccountCreationViewController
    : UIViewController <CaptchaViewControllerRefresh, UITextFieldDelegate,
                        UIScrollViewDelegate>

@property(weak, nonatomic) IBOutlet UITextField *usernameField;
@property(weak, nonatomic) IBOutlet UITextField *passwordField;
@property(weak, nonatomic) IBOutlet UITextField *passwordRepeatField;
@property(weak, nonatomic) IBOutlet UITextField *emailField;

@property(strong, nonatomic) CreateAccountFunnel *funnel;

@end
