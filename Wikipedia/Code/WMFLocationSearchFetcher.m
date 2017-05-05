#import "WMFLocationSearchFetcher.h"

//Networking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "WMFSearchResponseSerializer.h"
#import <Mantle/Mantle.h>
#import "WMFBaseRequestSerializer.h"

//Models
#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFLocationSearchErrorDomain = @"org.wikimedia.location.search";

#pragma mark - Internal Class Declarations

@interface WMFLocationSearchRequestParameters : NSObject
@property (nonatomic, copy) CLCircularRegion *region;
@property (nullable, nonatomic, copy) NSString *searchTerm;
@property (nonatomic, assign) NSUInteger numberOfResults;
@property (nonatomic, assign) WMFLocationSearchSortStyle sortStyle;
@end

@interface WMFLocationSearchRequestSerializer : WMFBaseRequestSerializer
@end

#pragma mark - Fetcher Implementation

@interface WMFLocationSearchFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager *operationManager;

@end

@implementation WMFLocationSearchFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.requestSerializer = [WMFLocationSearchRequestSerializer serializer];
        WMFSearchResponseSerializer *serializer = [WMFSearchResponseSerializer serializer];
        serializer.searchResultClass = [MWKLocationSearchResult class];
        manager.responseSerializer = serializer;
        self.operationManager = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (WMFLocationSearchRequestSerializer *)nearbySerializer {
    return (WMFLocationSearchRequestSerializer *)(self.operationManager.requestSerializer);
}

- (NSURLSessionDataTask *)fetchArticlesWithSiteURL:(NSURL *)siteURL
                                          location:(CLLocation *)location
                                       resultLimit:(NSUInteger)resultLimit
                                        completion:(void (^)(WMFLocationSearchResults *results))completion
                                           failure:(void (^)(NSError *error))failure {
    return [self fetchArticlesWithSiteURL:siteURL location:location resultLimit:resultLimit useDesktopURL:NO completion:completion failure:failure];
}

- (NSURLSessionDataTask *)fetchArticlesWithSiteURL:(NSURL *)siteURL
                                          location:(CLLocation *)location
                                       resultLimit:(NSUInteger)resultLimit
                                     useDesktopURL:(BOOL)useDeskTopURL
                                        completion:(void (^)(WMFLocationSearchResults *results))completion
                                           failure:(void (^)(NSError *error))failure {
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:location.coordinate radius:1000 identifier:@""];
    return [self fetchArticlesWithSiteURL:siteURL inRegion:region matchingSearchTerm:nil resultLimit:resultLimit useDesktopURL:useDeskTopURL completion:completion failure:failure];
}

- (NSURLSessionDataTask *)fetchArticlesWithSiteURL:(NSURL *)siteURL
                                          inRegion:(CLCircularRegion *)region
                                matchingSearchTerm:(nullable NSString *)searchTerm
                                         sortStyle:(WMFLocationSearchSortStyle)sortStyle
                                       resultLimit:(NSUInteger)resultLimit
                                        completion:(void (^)(WMFLocationSearchResults *results))completion
                                           failure:(void (^)(NSError *error))failure {
    return [self fetchArticlesWithSiteURL:siteURL inRegion:region matchingSearchTerm:searchTerm sortStyle:sortStyle resultLimit:resultLimit useDesktopURL:NO completion:completion failure:failure];
}

- (NSURLSessionDataTask *)fetchArticlesWithSiteURL:(NSURL *)siteURL
                                          inRegion:(CLCircularRegion *)region
                                matchingSearchTerm:(nullable NSString *)searchTerm
                                       resultLimit:(NSUInteger)resultLimit
                                     useDesktopURL:(BOOL)useDeskTopURL
                                        completion:(void (^)(WMFLocationSearchResults *results))completion
                                           failure:(void (^)(NSError *error))failure {
    return [self fetchArticlesWithSiteURL:siteURL inRegion:region matchingSearchTerm:searchTerm sortStyle:WMFLocationSearchSortStyleNone resultLimit:resultLimit useDesktopURL:useDeskTopURL completion:completion failure:failure];
}

- (NSURLSessionDataTask *)fetchArticlesWithSiteURL:(NSURL *)siteURL
                                          inRegion:(CLCircularRegion *)region
                                matchingSearchTerm:(nullable NSString *)searchTerm
                                         sortStyle:(WMFLocationSearchSortStyle)sortStyle
                                       resultLimit:(NSUInteger)resultLimit
                                     useDesktopURL:(BOOL)useDeskTopURL
                                        completion:(void (^)(WMFLocationSearchResults *results))completion
                                           failure:(void (^)(NSError *error))failure {
    NSURL *url = useDeskTopURL ? [NSURL wmf_desktopAPIURLForURL:siteURL] : [NSURL wmf_mobileAPIURLForURL:siteURL];

    WMFLocationSearchRequestParameters *params = [WMFLocationSearchRequestParameters new];
    params.region = region;
    params.numberOfResults = resultLimit;
    params.searchTerm = searchTerm;
    params.sortStyle = sortStyle;
    [[MWNetworkActivityIndicatorManager sharedManager] push];
    return [self.operationManager wmf_GETAndRetryWithURL:url
        parameters:params
        retry:NULL
        success:^(NSURLSessionDataTask *operation, id responseObject) {

            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            WMFLocationSearchResults *results = [[WMFLocationSearchResults alloc] initWithSearchSiteURL:siteURL region:region searchTerm:searchTerm results:responseObject];

            if (completion) {
                completion(results);
            }

        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            if (failure) {
                if (![[error domain] isEqualToString:NSURLErrorDomain]) {
                    error = [NSError errorWithDomain:WMFLocationSearchErrorDomain code:WMFLocationSearchErrorCodeUnknown userInfo:@{NSLocalizedDescriptionKey: WMFLocalizedStringWithDefaultValue(@"empty-no-search-results-message", nil, nil, @"No results found", @"Shown when there are no search results")}];
                }
                failure(error);
            }
        }];
}

@end

#pragma mark - Internal Class Implementations

@implementation WMFLocationSearchRequestParameters : NSObject
@end

@implementation WMFLocationSearchRequestSerializer

- (nullable NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                                        withParameters:(nullable id)parameters
                                                 error:(NSError *__autoreleasing *)error {
    NSDictionary *serializedParams = [self serializedParams:(WMFLocationSearchRequestParameters *)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary *)serializedParams:(WMFLocationSearchRequestParameters *)params {
    if (params.region.radius >= 10000 || params.searchTerm || params.sortStyle != WMFLocationSearchSortStyleNone) {
        NSMutableArray<NSString *> *gsrSearchArray = [NSMutableArray arrayWithCapacity:2];
        if (params.searchTerm) {
            [gsrSearchArray addObject:params.searchTerm];
        }
        NSString *nearcoord = [NSString stringWithFormat:@"nearcoord:%.0fkm,%.3f,%.3f", round(params.region.radius / 1000.0), params.region.center.latitude, params.region.center.longitude];
        [gsrSearchArray addObject:nearcoord];
        NSString *gsrsearch = [gsrSearchArray componentsJoinedByString:@" "];
        NSMutableDictionary<NSString *, NSObject *> *serializedParams = [NSMutableDictionary dictionaryWithDictionary:@{
            @"action": @"query",
            @"prop": @"coordinates|pageimages|pageterms",
            @"coprop": @"type|dim",
            @"colimit": @(params.numberOfResults),
            @"generator": @"search",
            @"gsrsearch": gsrsearch,
            @"gsrlimit": @(params.numberOfResults),
            @"piprop": @"thumbnail",
            //@"pilicense": @"any",
            @"pithumbsize": [[UIScreen mainScreen] wmf_nearbyThumbnailWidthForScale],
            @"pilimit": @(params.numberOfResults),
            @"format": @"json",
        }];
        switch (params.sortStyle) {
            case WMFLocationSearchSortStyleLinks:
                serializedParams[@"cirrusIncLinkssW"] = @(1000);
                break;
            case WMFLocationSearchSortStylePageViews:
                serializedParams[@"cirrusPageViewsW"] = @(1000);
                break;
            case WMFLocationSearchSortStylePageViewsAndLinks:
                serializedParams[@"cirrusPageViewsW"] = @(1000);
                serializedParams[@"cirrusIncLinkssW"] = @(1000);
                break;
            default:
                break;
        }
        return serializedParams;
    } else {
        NSString *coords =
            [NSString stringWithFormat:@"%f|%f", params.region.center.latitude, params.region.center.longitude];
        return @{
            @"action": @"query",
            @"prop": @"coordinates|pageimages|pageterms",
            @"coprop": @"type|dim",
            @"colimit": @(params.numberOfResults),
            @"pithumbsize": [[UIScreen mainScreen] wmf_nearbyThumbnailWidthForScale],
            @"pilimit": @(params.numberOfResults),
            //@"pilicense": @"any",
            @"wbptterms": @"description",
            @"generator": @"geosearch",
            @"ggscoord": coords,
            @"codistancefrompoint": coords,
            @"ggsradius": @(params.region.radius),
            @"ggslimit": @(params.numberOfResults),
            @"format": @"json"
        };
    }
}

@end

NS_ASSUME_NONNULL_END
