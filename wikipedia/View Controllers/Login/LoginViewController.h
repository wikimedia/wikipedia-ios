//  Created by Monte Hurd on 2/10/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

#import "LoginFunnel.h"
#import "FetcherBase.h"

@interface LoginViewController : UIViewController <FetchFinishedDelegate>

- (IBAction)createAccountButtonPushed:(id)sender;

- (void)loginWithUserName: (NSString *)userName
                 password: (NSString *)password
                onSuccess: (void (^)(void))successBlock
                   onFail: (void (^)(void))failBlock;

@property (strong, nonatomic) LoginFunnel *funnel;

@property (weak, nonatomic) id truePresentingVC;
@property (weak, nonatomic) TopMenuViewController *topMenuViewController;

@end
