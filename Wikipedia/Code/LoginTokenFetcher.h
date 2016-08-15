#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, LoginTokenErrorType) {
    LOGIN_TOKEN_ERROR_UNKNOWN = 0,
    LOGIN_TOKEN_ERROR_API = 1
};

@class AFHTTPSessionManager;

@interface LoginTokenFetcher : FetcherBase

@property(strong, nonatomic, readonly) NSString *domain;
@property(strong, nonatomic, readonly) NSString *userName;
@property(strong, nonatomic, readonly) NSString *password;
@property(strong, nonatomic, readonly) NSString *token;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndFetchTokenForDomain:(NSString *)domain
                                  userName:(NSString *)userName
                                  password:(NSString *)password
                               withManager:(AFHTTPSessionManager *)manager
                        thenNotifyDelegate:(id<FetchFinishedDelegate>)delegate;
@end
