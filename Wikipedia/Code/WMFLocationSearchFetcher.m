

#import "WMFLocationSearchFetcher.h"

//Networking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "WMFSearchResponseSerializer.h"
#import <Mantle/Mantle.h>
#import "UIScreen+WMFImageWidth.h"

//Promises
#import "Wikipedia-Swift.h"

//Models
#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"
#import "MWKSite.h"
#import "MWKTitle.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Internal Class Declarations

@interface WMFLocationSearchRequestParameters : NSObject
@property (nonatomic, strong) CLLocation* location;
@property (nonatomic, assign) NSUInteger numberOfResults;
@end

@interface WMFLocationSearchRequestSerializer : AFHTTPRequestSerializer
@end

#pragma mark - Fetcher Implementation

@interface WMFLocationSearchFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager* operationManager;

@end

@implementation WMFLocationSearchFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager* manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.requestSerializer = [WMFLocationSearchRequestSerializer serializer];
        WMFSearchResponseSerializer* serializer = [WMFSearchResponseSerializer serializer];
        serializer.searchResultClass = [MWKLocationSearchResult class];
        manager.responseSerializer   = serializer;
        self.operationManager        = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (WMFLocationSearchRequestSerializer*)nearbySerializer {
    return (WMFLocationSearchRequestSerializer*)(self.operationManager.requestSerializer);
}

- (AnyPromise*)fetchArticlesWithSite:(MWKSite*)site
                            location:(CLLocation*)location
                         resultLimit:(NSUInteger)resultLimit
                         cancellable:(inout id<Cancellable> __nullable* __nullable)outCancellable {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        id<Cancellable> cancellable =
            [self fetchNearbyArticlesWithSite:site
                                     location:location
                                  resultLimit:resultLimit
                                useDesktopURL:NO
                                     resolver:resolve];
        WMFSafeAssign(outCancellable, cancellable);
    }];
}

- (id<Cancellable>)fetchNearbyArticlesWithSite:(MWKSite*)site
                                      location:(CLLocation*)location
                                   resultLimit:(NSUInteger)resultLimit
                                 useDesktopURL:(BOOL)useDeskTopURL
                                      resolver:(PMKResolver)resolve {
    NSURL* url = [site apiEndpoint:useDeskTopURL];

    WMFLocationSearchRequestParameters* params = [WMFLocationSearchRequestParameters new];
    params.location        = location;
    params.numberOfResults = resultLimit;

    return [self.operationManager GET:url.absoluteString
                           parameters:params
                             progress:NULL
                              success:^(NSURLSessionDataTask* operation, id response) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        WMFLocationSearchResults* results = [[WMFLocationSearchResults alloc] initWithSite:site location:location results:response];
        resolve(results);
    }
                              failure:^(NSURLSessionDataTask* operation, NSError* error) {
        if ([url isEqual:[site mobileApiEndpoint]] && [error wmf_shouldFallbackToDesktopURLError]) {
            [self fetchNearbyArticlesWithSite:site
                                     location:location
                                  resultLimit:resultLimit
                                useDesktopURL:NO
                                     resolver:resolve];
        } else {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }
    }];
}

@end

#pragma mark - Internal Class Implementations

@implementation WMFLocationSearchRequestParameters : NSObject
@end

@implementation WMFLocationSearchRequestSerializer

- (nullable NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                                       withParameters:(nullable id)parameters
                                                error:(NSError* __autoreleasing*)error {
    NSDictionary* serializedParams = [self serializedParams:(WMFLocationSearchRequestParameters*)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary*)serializedParams:(WMFLocationSearchRequestParameters*)params {
    NSString* coords =
        [NSString stringWithFormat:@"%f|%f", params.location.coordinate.latitude, params.location.coordinate.longitude];
    NSString* numberOfResults = [NSString stringWithFormat:@"%lu", (unsigned long)params.numberOfResults];

    return @{
               @"action": @"query",
               @"prop": @"coordinates|pageimages|pageterms",
               @"colimit": numberOfResults,
               @"pithumbsize": [[UIScreen mainScreen] wmf_nearbyThumbnailWidthForScale],
               @"pilimit": numberOfResults,
               @"wbptterms": @"description",
               @"generator": @"geosearch",
               @"ggscoord": coords,
               @"codistancefrompoint": coords,
               @"ggsradius": @"10000",
               @"ggslimit": numberOfResults,
               @"format": @"json"
    };
}

@end


NS_ASSUME_NONNULL_END
