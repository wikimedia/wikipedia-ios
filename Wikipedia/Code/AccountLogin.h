//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

extern NSString* const WMFAccountLoginErrorDomain;

typedef NS_ENUM (NSInteger, LoginErrorType) {
    LOGIN_ERROR_UNKNOWN,
    LOGIN_ERROR_API,
    LOGIN_ERROR_NAME_REQUIRED,
    LOGIN_ERROR_NAME_ILLEGAL,
    LOGIN_ERROR_NAME_NOT_FOUND,
    LOGIN_ERROR_PASSWORD_REQUIRED,
    LOGIN_ERROR_PASSWORD_WRONG,
    LOGIN_ERROR_THROTTLED,
    LOGIN_ERROR_BLOCKED
};

@class AFHTTPSessionManager;

@interface AccountLogin : FetcherBase

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndLoginForDomain:(NSString*)domain
                             userName:(NSString*)userName
                             password:(NSString*)password
                                token:(NSString*)token
                       useAuthManager:(BOOL)useAuthManager
                          withManager:(AFHTTPSessionManager*)manager
                   thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate;
@end
