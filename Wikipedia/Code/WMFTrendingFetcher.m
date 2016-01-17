
#import "WMFTrendingFetcher.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "WMFNetworkUtilities.h"
#import "MWKSite.h"

@interface WMFTrendingFetcher ()
@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;
@end

@implementation WMFTrendingFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        self.operationManager = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (AnyPromise*)fetchTrendingForSite:(MWKSite*)site date:(NSDate*)date {
    NSParameterAssert(site);
    NSParameterAssert(date);
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self.operationManager GET:[self getTrendingURLStringForSite:site date:date]
                        parameters:nil
                           success:^(AFHTTPRequestOperation* operation, id responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            NSArray* articles = [[responseObject valueForKeyPath:@"items.articles"] firstObject];

            NSArray* topArticles = [articles subarrayWithRange:NSMakeRange(0, MIN(30, articles.count))];

            resolve(topArticles);
        }
                           failure:^(AFHTTPRequestOperation* operation, NSError* error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }];
    }];
}

- (NSString*)getTrendingURLStringForSite:(MWKSite*)site date:(NSDate*)date {
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd"];
    NSString* dateString = [formatter stringFromDate:date];
    return [NSString stringWithFormat:@"https://wikimedia.org/api/rest_v1/metrics/pageviews/top/%@.wikipedia/all-access/%@", site.language, dateString];
}

@end
