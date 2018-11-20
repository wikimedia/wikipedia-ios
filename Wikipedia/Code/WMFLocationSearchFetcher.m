#import <WMF/WMFLocationSearchFetcher.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/WMFLocalization.h>
#import <WMF/UIScreen+WMFImageWidth.h>
#import <WMF/WMFNumberOfExtractCharacters.h>

//Networking
#import <WMF/MWNetworkActivityIndicatorManager.h>
#import <WMF/AFHTTPSessionManager+WMFConfig.h>
#import <WMF/WMFSearchResponseSerializer.h>
@import Mantle;
#import <WMF/WMFBaseRequestSerializer.h>

//Models
#import <WMF/WMFLocationSearchResults.h>
#import <WMF/MWKLocationSearchResult.h>

#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFLocationSearchErrorDomain = @"org.wikimedia.location.search";

#pragma mark - Fetcher Implementation

@interface WMFLocationSearchFetcher ()

@property (nonatomic, strong) WMFSession *session;

@end

@implementation WMFLocationSearchFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.session = [WMFSession shared];
    }
    return self;
}

- (void)fetchArticlesWithSiteURL:(NSURL *)siteURL
                        location:(CLLocation *)location
                     resultLimit:(NSUInteger)resultLimit
                      completion:(void (^)(WMFLocationSearchResults *results))completion
                         failure:(void (^)(NSError *error))failure {
    [self fetchArticlesWithSiteURL:siteURL location:location resultLimit:resultLimit useDesktopURL:NO completion:completion failure:failure];
}

- (void)fetchArticlesWithSiteURL:(NSURL *)siteURL
                        location:(CLLocation *)location
                     resultLimit:(NSUInteger)resultLimit
                   useDesktopURL:(BOOL)useDeskTopURL
                      completion:(void (^)(WMFLocationSearchResults *results))completion
                         failure:(void (^)(NSError *error))failure {
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:location.coordinate radius:1000 identifier:@""];
    [self fetchArticlesWithSiteURL:siteURL inRegion:region matchingSearchTerm:nil resultLimit:resultLimit useDesktopURL:useDeskTopURL completion:completion failure:failure];
}

- (void)fetchArticlesWithSiteURL:(NSURL *)siteURL
                        inRegion:(CLCircularRegion *)region
              matchingSearchTerm:(nullable NSString *)searchTerm
                       sortStyle:(WMFLocationSearchSortStyle)sortStyle
                     resultLimit:(NSUInteger)resultLimit
                      completion:(void (^)(WMFLocationSearchResults *results))completion
                         failure:(void (^)(NSError *error))failure {
    [self fetchArticlesWithSiteURL:siteURL inRegion:region matchingSearchTerm:searchTerm sortStyle:sortStyle resultLimit:resultLimit useDesktopURL:NO completion:completion failure:failure];
}

- (void)fetchArticlesWithSiteURL:(NSURL *)siteURL
                        inRegion:(CLCircularRegion *)region
              matchingSearchTerm:(nullable NSString *)searchTerm
                     resultLimit:(NSUInteger)resultLimit
                   useDesktopURL:(BOOL)useDeskTopURL
                      completion:(void (^)(WMFLocationSearchResults *results))completion
                         failure:(void (^)(NSError *error))failure {
    [self fetchArticlesWithSiteURL:siteURL inRegion:region matchingSearchTerm:searchTerm sortStyle:WMFLocationSearchSortStyleNone resultLimit:resultLimit useDesktopURL:useDeskTopURL completion:completion failure:failure];
}

- (void)fetchArticlesWithSiteURL:(NSURL *)siteURL
                        inRegion:(CLCircularRegion *)region
              matchingSearchTerm:(nullable NSString *)searchTerm
                       sortStyle:(WMFLocationSearchSortStyle)sortStyle
                     resultLimit:(NSUInteger)resultLimit
                   useDesktopURL:(BOOL)useDeskTopURL
                      completion:(void (^)(WMFLocationSearchResults *results))completion
                         failure:(void (^)(NSError *error))failure {

    NSURL *url;

    NSDictionary *params = [self params:region searchTerm:searchTerm resultLimit:resultLimit sortStyle:sortStyle];

    if (useDeskTopURL) {
        url = [[WMFConfiguration.current mediaWikiAPIURLComponentsForHost:siteURL.host withQueryParameters:params] URL];
    } else {
        url =[[WMFConfiguration.current mobileMediaWikiAPIURLComponentsForHost:siteURL.host withQueryParameters:params] URL];
    }

    assert(url);

    [self.session getJSONDictionaryFromURL:url
                               ignoreCache:YES
                         completionHandler:^(NSDictionary<NSString *, id> *_Nullable result, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
                             if (error) {
                                 if (![[error domain] isEqualToString:NSURLErrorDomain]) {
                                     error = [NSError errorWithDomain:WMFLocationSearchErrorDomain code:WMFLocationSearchErrorCodeNoResults userInfo:@{NSLocalizedDescriptionKey: WMFLocalizedStringWithDefaultValue(@"empty-no-search-results-message", nil, nil, @"No results found", @"Shown when there are no search results")}];
                                 }
                                 failure(error);
                                 return;
                             }

                             if (response.statusCode == 304) {
                                 NSError *error = [NSError wmf_errorWithType:WMFErrorTypeNoNewData userInfo:nil];
                                 failure(error);
                                 return;
                             }

                             NSDictionary *pagesGroupedById = result[@"query"][@"pages"];
                             if (![pagesGroupedById isKindOfClass:[NSDictionary class]]) {
                                 NSError *error = [NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType userInfo:nil];
                                 failure(error);
                                 return;
                             }

                             NSArray *pages = pagesGroupedById.allValues;
                             if (![pages isKindOfClass:[NSArray class]]) {
                                 NSError *error = [NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType userInfo:nil];
                                 failure(error);
                                 return;
                             }

                             NSError *mantleError = nil;
                             NSArray<MWKLocationSearchResult *> *results = [MTLJSONAdapter modelsOfClass:[MWKLocationSearchResult class] fromJSONArray:pages error:&mantleError];
                             if (mantleError) {
                                 failure(mantleError);
                                 return;
                             }
                             WMFLocationSearchResults *locationSearchResults = [[WMFLocationSearchResults alloc] initWithSearchSiteURL:siteURL region:region searchTerm:searchTerm results:results];
                             completion(locationSearchResults);
                         }];
}

- (NSDictionary *)params:(CLCircularRegion *)region searchTerm:(nullable NSString *)searchTerm resultLimit:(NSUInteger)resultLimit sortStyle:(WMFLocationSearchSortStyle)sortStyle {
    NSDictionary *defaultParams = @{@"action": @"query",
                                    @"coprop": @"type|dim",
                                    @"colimit": @(resultLimit),
                                    @"gsrlimit": @(resultLimit),
                                    @"format": @"json",
                                    @"ppprop": @"displaytitle|disambiguation",
                                    @"pilimit": @(resultLimit),
                                    @"pilimit": @(resultLimit),
                                    @"pithumbsize": [[UIScreen mainScreen] wmf_nearbyThumbnailWidthForScale]};

    NSMutableDictionary<NSString *, NSObject *> *params = [NSMutableDictionary dictionaryWithDictionary:defaultParams];

    if (region.radius >= 10000 || searchTerm || sortStyle != WMFLocationSearchSortStyleNone) {
        NSMutableArray<NSString *> *gsrSearchArray = [NSMutableArray arrayWithCapacity:2];
        if (searchTerm) {
            [gsrSearchArray addObject:searchTerm];
        }
        CLLocationDistance radius = MAX(1, ceil(region.radius));
        NSString *nearcoord = [NSString stringWithFormat:@"nearcoord:%.0fm,%.3f,%.3f", radius, region.center.latitude, region.center.longitude];
        [gsrSearchArray addObject:nearcoord];
        NSString *gsrsearch = [gsrSearchArray componentsJoinedByString:@" "];

        NSDictionary *additionalParams = @{@"generator": @"search",
                                           @"gsrsearch": gsrsearch,
                                           @"piprop": @"thumbnail"};

        [params addEntriesFromDictionary:additionalParams];

        switch (sortStyle) {
            case WMFLocationSearchSortStyleLinks:
                params[@"cirrusIncLinkssW"] = @(1000);
                break;
            case WMFLocationSearchSortStylePageViews:
                params[@"cirrusPageViewsW"] = @(1000);
                break;
            case WMFLocationSearchSortStylePageViewsAndLinks:
                params[@"cirrusPageViewsW"] = @(1000);
                params[@"cirrusIncLinkssW"] = @(1000);
                break;
            default:
                break;
        }
    } else {
        NSString *coords =
            [NSString stringWithFormat:@"%f|%f", region.center.latitude, region.center.longitude];
        NSDictionary *additionalParams = @{ //@"pilicense": @"any",
            @"generator": @"geosearch",
            @"ggscoord": coords,
            @"codistancefrompoint": coords,
            @"ggsradius": @(region.radius),
            @"ggslimit": @(resultLimit),
            @"exintro": @YES,
            @"exlimit": @(resultLimit),
            @"explaintext": @"",
            @"exchars": @(WMFNumberOfExtractCharacters)
        };

        [params addEntriesFromDictionary:additionalParams];
    }

    return params;
}

@end

NS_ASSUME_NONNULL_END
