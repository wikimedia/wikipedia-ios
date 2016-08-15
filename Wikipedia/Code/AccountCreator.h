#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM (NSInteger, AccountCreationErrorType) {
    ACCOUNT_CREATION_ERROR_UNKNOWN       = 0,
    ACCOUNT_CREATION_ERROR_API           = 1,
    ACCOUNT_CREATION_ERROR_NEEDS_CAPTCHA = 2
};

@class AFHTTPSessionManager;

@interface AccountCreator : FetcherBase

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndCreateAccountForUserName:(NSString*)userName
                                       realName:(NSString*)realName
                                         domain:(NSString*)domain
                                       password:(NSString*)password
                                          email:(NSString*)email
                                      captchaId:(NSString*)captchaId
                                    captchaWord:(NSString*)captchaWord
                                          token:(NSString*)token
                                    withManager:(AFHTTPSessionManager*)manager
                             thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate;

@end
