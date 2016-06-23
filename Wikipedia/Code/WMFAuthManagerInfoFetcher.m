
#import "WMFAuthManagerInfoFetcher.h"
#import "AFHTTPSessionManager+WMFDesktopRetry.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFAuthManagerInfo.h"
#import "MWKSite.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFAuthManagerInfoFetcher ()
@property (nonatomic, strong) AFHTTPSessionManager* operationManager;
@end

@implementation WMFAuthManagerInfoFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager* manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.responseSerializer = [WMFMantleJSONResponseSerializer serializerForInstancesOf:[WMFAuthManagerInfo class] fromKeypath:@"query"];
        self.operationManager      = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (void)fetchAuthManagerCreationAvailableForSite:(MWKSite*)site success:(WMFAuthManagerInfoBlock)success failure:(WMFErrorHandler)failure {
    [self fetchAuthManagerAvailableForSite:site type:@"create" success:success failure:failure];
}

- (void)fetchAuthManagerLoginAvailableForSite:(MWKSite*)site success:(WMFAuthManagerInfoBlock)success failure:(WMFErrorHandler)failure {
    [self fetchAuthManagerAvailableForSite:site type:@"login" success:success failure:failure];
}

- (void)fetchAuthManagerAvailableForSite:(MWKSite*)site type:(NSString*)type success:(WMFAuthManagerInfoBlock)success failure:(WMFErrorHandler)failure {
    NSDictionary* params = @{
        @"action": @"query",
        @"meta": @"authmanagerinfo",
        @"format": @"json",
        @"amirequestsfor": type
    };

    [self.operationManager wmf_GETWithSite:site parameters:params retry:NULL success:^(NSURLSessionDataTask* operation, id responseObject) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        success(responseObject);
    } failure:^(NSURLSessionDataTask* operation, NSError* error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        failure(error);
    }];
}

@end

NS_ASSUME_NONNULL_END
