
#import "MWKSiteInfoFetcher.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "WMFNetworkUtilities.h"
#import "WMFApiJsonResponseSerializer.h"
#import "MWKSite.h"
#import "MWKSiteInfo.h"

@interface MWKSiteInfoFetcher ()
@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;
@end

@implementation MWKSiteInfoFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.responseSerializer = [WMFApiJsonResponseSerializer serializer];
        self.operationManager      = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (AnyPromise*)fetchSiteInfoForSite:(MWKSite*)site {
    NSParameterAssert(site);
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSDictionary* params = @{
            @"action": @"query",
            @"meta": @"siteinfo",
            @"format": @"json",
            @"siprop": @"general"
        };

        [self.operationManager wmf_GETWithSite:site
                                    parameters:params
                                         retry:NULL
                                       success:^(AFHTTPRequestOperation* operation, id responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            NSDictionary* generalProps = [responseObject valueForKeyPath:@"query.general"];
            MWKSiteInfo* info = [[MWKSiteInfo alloc] initWithSite:site mainPageTitleText:generalProps[@"mainpage"]];
            resolve(info);
        }
                                       failure:^(AFHTTPRequestOperation* operation, NSError* error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }];
    }];
}

@end
