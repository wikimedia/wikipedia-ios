//  Created by Monte Hurd on 2/10/14.

#import <UIKit/UIKit.h>

#import "MWNetworkOp.h"

@interface LoginViewController : UIViewController <NetworkOpDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;

- (IBAction)createAccountButtonPushed:(id)sender;

@end
