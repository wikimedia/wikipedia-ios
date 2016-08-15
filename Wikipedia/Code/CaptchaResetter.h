#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, CaptchaResetterErrorType) {
  CAPTCHA_RESET_ERROR_UNKNOWN = 0,
  CAPTCHA_RESET_ERROR_API = 1
};

@class AFHTTPSessionManager;

@interface CaptchaResetter : FetcherBase

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndResetCaptchaForDomain:(NSString *)domain
                                 withManager:(AFHTTPSessionManager *)manager
                          thenNotifyDelegate:(id<FetchFinishedDelegate>)delegate;

+ (NSString *)newCaptchaImageUrlFromOldUrl:(NSString *)oldUrl andNewId:(NSString *)newId;

@end
