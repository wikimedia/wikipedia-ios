#import "AccountCreationTokenFetcher.h"
#import <AFNetworking/AFNetworking.h>
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+WMFExtras.h"

@interface AccountCreationTokenFetcher ()

@property(strong, nonatomic) NSString *domain;
@property(strong, nonatomic) NSString *userName;
@property(strong, nonatomic) NSString *password;
@property(strong, nonatomic) NSString *email;
@property(strong, nonatomic) NSString *token;

@end

@implementation AccountCreationTokenFetcher

- (instancetype)initAndFetchTokenForDomain:(NSString *)domain
                                  userName:(NSString *)userName
                                  password:(NSString *)password
                                     email:(NSString *)email
                               withManager:(AFHTTPSessionManager *)manager
                        thenNotifyDelegate:(id<FetchFinishedDelegate>)delegate {
  self = [super init];
  if (self) {
    self.domain = domain ? domain : @"";
    self.userName = userName ? userName : @"";
    self.password = password ? password : @"";
    self.email = email ? email : @"";
    self.token = @"";

    self.fetchFinishedDelegate = delegate;
    [self fetchTokenWithManager:manager];
  }
  return self;
}

- (void)fetchTokenWithManager:(AFHTTPSessionManager *)manager {
  NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:self.domain];

  NSDictionary *params = @{
    @"action" : @"query",
    @"meta" : @"tokens",
    @"type" : @"createaccount",
    @"format" : @"json"
  };

  [[MWNetworkActivityIndicatorManager sharedManager] push];

  [manager POST:url.absoluteString
      parameters:params
      progress:NULL
      success:^(NSURLSessionDataTask *operation, id responseObject) {
        // NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        NSError *error = nil;
        if (![responseObject isDict]) {
          error = [NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType
                                    userInfo:nil];
        } else if (responseObject[@"error"]) {
          NSMutableDictionary *errorDict =
              [responseObject[@"error"] mutableCopy];
          errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
          error = [NSError errorWithDomain:@"Acct Creation Token Fetcher"
                                      code:ACCOUNT_CREATION_TOKEN_ERROR_API
                                  userInfo:errorDict];
        }

        self.token = responseObject[@"query"][@"tokens"][@"createaccounttoken"];
        [self finishWithError:error fetchedData:self.token];
      }
      failure:^(NSURLSessionDataTask *operation, NSError *error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError:error fetchedData:nil];
      }];
}

@end
