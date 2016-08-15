#import "WMFAuthManagerInfoFetcher.h"
#import "AFHTTPSessionManager+WMFDesktopRetry.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFAuthManagerInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFAuthManagerInfoFetcher ()
@property(nonatomic, strong) AFHTTPSessionManager *operationManager;
@end

@implementation WMFAuthManagerInfoFetcher

- (instancetype)init {
  self = [super init];
  if (self) {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
    manager.responseSerializer = [WMFMantleJSONResponseSerializer serializerForInstancesOf:[WMFAuthManagerInfo class] fromKeypath:@"query"];
    self.operationManager = manager;
  }
  return self;
}

- (BOOL)isFetching {
  return [[self.operationManager operationQueue] operationCount] > 0;
}

- (void)fetchAuthManagerCreationAvailableForSiteURL:(NSURL *)siteURL success:(WMFAuthManagerInfoBlock)success failure:(WMFErrorHandler)failure {
  [self fetchAuthManagerAvailableForSiteURL:siteURL type:@"create" success:success failure:failure];
}

- (void)fetchAuthManagerLoginAvailableForSiteURL:(NSURL *)siteURL success:(WMFAuthManagerInfoBlock)success failure:(WMFErrorHandler)failure {
  [self fetchAuthManagerAvailableForSiteURL:siteURL type:@"login" success:success failure:failure];
}

- (void)fetchAuthManagerAvailableForSiteURL:(NSURL *)siteURL type:(NSString *)type success:(WMFAuthManagerInfoBlock)success failure:(WMFErrorHandler)failure {
  NSDictionary *params = @{
    @"action" : @"query",
    @"meta" : @"authmanagerinfo",
    @"format" : @"json",
    @"amirequestsfor" : type
  };

  [self.operationManager wmf_GETAndRetryWithURL:siteURL
      parameters:params
      retry:NULL
      success:^(NSURLSessionDataTask *operation, id responseObject) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        success(responseObject);
      }
      failure:^(NSURLSessionDataTask *operation, NSError *error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        failure(error);
      }];
}

@end

NS_ASSUME_NONNULL_END
