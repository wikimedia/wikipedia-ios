//  Created by Monte Hurd on 2/10/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

#import "MWNetworkOp.h"

@interface LoginViewController : UIViewController <NetworkOpDelegate>

- (IBAction)createAccountButtonPushed:(id)sender;

- (void)loginWithUserName: (NSString *)userName
                 password: (NSString *)password
                onSuccess: (void (^)(void))successBlock
                   onFail: (void (^)(void))failBlock;

@end
