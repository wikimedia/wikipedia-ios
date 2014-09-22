//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, AccountCreationErrorType) {
    ACCOUNT_CREATION_ERROR_UNKNOWN = 0,
    ACCOUNT_CREATION_ERROR_API = 1,
    ACCOUNT_CREATION_ERROR_NEEDS_CAPTCHA = 2
};

@class AFHTTPRequestOperationManager;

@interface AccountCreator : FetcherBase

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndCreateAccountForUserName: (NSString *)userName
                                      realName: (NSString *)realName
                                        domain: (NSString *)domain
                                      password: (NSString *)password
                                         email: (NSString *)email
                                     captchaId: (NSString *)captchaId
                                   captchaWord: (NSString *)captchaWord
                                         token: (NSString *)token
                                   withManager: (AFHTTPRequestOperationManager *)manager
                            thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
