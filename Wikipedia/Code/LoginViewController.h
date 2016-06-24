
#import <UIKit/UIKit.h>
#import "LoginFunnel.h"

@interface LoginViewController : UIViewController

- (IBAction)createAccountButtonPushed:(id)sender;

- (void)loginWithUserName:(NSString*)userName
                 password:(NSString*)password
                onSuccess:(void (^)(void))successBlock
                   onFail:(void (^)(void))failBlock;

@property (strong, nonatomic) LoginFunnel* funnel;

@end
