//  Created by Monte Hurd on 2/10/14.

#import <UIKit/UIKit.h>

#import "MWNetworkOp.h"

@interface LoginViewController : UIViewController <NetworkOpDelegate>

- (IBAction)createAccountButtonPushed:(id)sender;

- (void)loginWithUserName: (NSString *)userName
                 password: (NSString *)password
                onSuccess: (void (^)(void))successBlock
                   onFail: (void (^)(void))failBlock;

@end
