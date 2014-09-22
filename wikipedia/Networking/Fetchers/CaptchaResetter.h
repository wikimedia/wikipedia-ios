//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, CaptchaResetterErrorType) {
    CAPTCHA_RESET_ERROR_UNKNOWN = 0,
    CAPTCHA_RESET_ERROR_API = 1
};

@class AFHTTPRequestOperationManager;

@interface CaptchaResetter : FetcherBase

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndResetCaptchaForDomain: (NSString *)domain
                                withManager: (AFHTTPRequestOperationManager *)manager
                         thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
