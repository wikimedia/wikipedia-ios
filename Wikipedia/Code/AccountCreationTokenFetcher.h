#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, AccountCreationTokenErrorType) {
  ACCOUNT_CREATION_TOKEN_ERROR_UNKNOWN = 0,
  ACCOUNT_CREATION_TOKEN_ERROR_API = 1
};

@class AFHTTPSessionManager;

@interface AccountCreationTokenFetcher : FetcherBase

@property(strong, nonatomic, readonly) NSString *domain;
@property(strong, nonatomic, readonly) NSString *userName;
@property(strong, nonatomic, readonly) NSString *password;
@property(strong, nonatomic, readonly) NSString *email;
@property(strong, nonatomic, readonly) NSString *token;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndFetchTokenForDomain:(NSString *)domain
                                  userName:(NSString *)userName
                                  password:(NSString *)password
                                     email:(NSString *)email
                               withManager:(AFHTTPSessionManager *)manager
                        thenNotifyDelegate:(id<FetchFinishedDelegate>)delegate;
@end
