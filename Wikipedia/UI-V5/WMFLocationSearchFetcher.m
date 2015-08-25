

#import "WMFLocationSearchFetcher.h"

//Networking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "WMFSearchResponseSerializer.h"
#import <Mantle/Mantle.h>

//Promises
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

//Models
#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"

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

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@end

@implementation WMFLocationSearchFetcher

- (instancetype)initWithSearchSite:(MWKSite*)site {
    self = [super init];
    if (self) {
        NSParameterAssert(site);
        self.searchSite = site;
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
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

- (AnyPromise*)fetchArticlesWithLocation:(CLLocation*)location {
    return [self fetchNearbyArticlesWithLocation:location useDesktopURL:NO];
}

- (AnyPromise*)fetchNearbyArticlesWithLocation:(CLLocation*)location useDesktopURL:(BOOL)useDeskTopURL {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSURL* url = [self.searchSite apiEndpoint:useDeskTopURL];

        WMFLocationSearchRequestParameters* params = [WMFLocationSearchRequestParameters new];
        params.location = location;
        params.numberOfResults = self.maximumNumberOfResults;

        [self.operationManager GET:url.absoluteString parameters:params success:^(AFHTTPRequestOperation* operation, id response) {
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

#pragma mark - Internal Class Implementations

@implementation WMFLocationSearchRequestParameters : NSObject
@end

// Reminder: For caching reasons, don't do "(scale * 320)" here.
#define LEAD_IMAGE_WIDTH (([UIScreen mainScreen].scale > 1) ? 640 : 320)

@implementation WMFLocationSearchRequestSerializer

- (NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                              withParameters:(id)parameters
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
               @"pithumbsize": @(LEAD_IMAGE_WIDTH),
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


@implementation WMFLocationSearchResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse*)response
                           data:(NSData*)data
                          error:(NSError* __autoreleasing*)error {
    NSDictionary* JSON                    = [super responseObjectForResponse:response data:data error:error];
    NSDictionary* nearbyResultsDictionary = JSON[@"query"][@"pages"];
    NSArray* nearbyResultsArray           = [nearbyResultsDictionary allValues];

    NSArray* results = [MTLJSONAdapter modelsOfClass:[MWKLocationSearchResult class] fromJSONArray:nearbyResultsArray error:error];
    return [results sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:WMF_SAFE_KEYPATH([MWKLocationSearchResult new], distanceFromQueryCoordinates) ascending:YES]]];
}

@end


NS_ASSUME_NONNULL_END
