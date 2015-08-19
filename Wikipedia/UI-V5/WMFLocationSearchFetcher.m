

#import "WMFLocationSearchFetcher.h"

//AFNetworking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "WMFLocationSearchRequestSerializer.h"
#import "WMFLocationSearchResponseSerializer.h"

//Promises
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

#import "WMFLocationSearchResults.h"
#import "MWKNearbyArticleResult.h"

@interface WMFLocationSearchFetcher ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@end

@implementation WMFLocationSearchFetcher

- (instancetype)initWithSearchSite:(MWKSite*)site{
    self = [super init];
    if (self) {
        NSParameterAssert(site);
        self.searchSite  = site;
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.requestSerializer  = [WMFLocationSearchRequestSerializer serializer];
        manager.responseSerializer = [WMFLocationSearchResponseSerializer serializer];
        self.operationManager = manager;
    }
    return self;
}

- (WMFLocationSearchRequestSerializer*)nearbySerializer{
    return (WMFLocationSearchRequestSerializer*)(self.operationManager.requestSerializer);
}

- (void)setMaximumNumberOfResults:(NSUInteger)maximumNumberOfResults{
    [[self nearbySerializer] setMaximumNumberOfResults:maximumNumberOfResults];
}

- (NSUInteger)maximumNumberOfResults{
    return [[self nearbySerializer] maximumNumberOfResults];
}

- (AnyPromise*)fetchArticlesWithLocation:(CLLocation*)location{
    return [self fetchNearbyArticlesWithLocation:location useDesktopURL:NO];
}

- (AnyPromise*)fetchNearbyArticlesWithLocation:(CLLocation*)location useDesktopURL:(BOOL)useDeskTopURL{
 
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        
        NSURL* url = useDeskTopURL ? [self.searchSite apiEndpoint] : [self.searchSite mobileApiEndpoint];
        
        [self.operationManager GET:url.absoluteString parameters:location success:^(AFHTTPRequestOperation* operation, id response) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            WMFLocationSearchResults* results = [[WMFLocationSearchResults alloc] initWithLocation:location results:response];
            resolve(results);
        } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
            if ([url isEqual:[self.searchSite mobileApiEndpoint]] && [error wmf_shouldFallbackToDesktopURLError]) {
                [self fetchNearbyArticlesWithLocation:location useDesktopURL:YES];
            } else {
                [[MWNetworkActivityIndicatorManager sharedManager] pop];
                resolve(error);
            }
        }];
    }];
}


@end
