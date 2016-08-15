#import <UIKit/UIKit.h>
#import "LoginFunnel.h"

@interface LoginViewController : UIViewController

- (IBAction)createAccountButtonPushed:(id)sender;

@property (strong, nonatomic) LoginFunnel* funnel;

@end
