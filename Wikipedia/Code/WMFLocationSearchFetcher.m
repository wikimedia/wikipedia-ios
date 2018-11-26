#import <WMF/WMFLocationSearchFetcher.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/WMFLocalization.h>
#import <WMF/UIScreen+WMFImageWidth.h>
#import <WMF/WMFNumberOfExtractCharacters.h>
#import <WMF/WMFLegacySerializer.h>

//Networking
#import <WMF/MWNetworkActivityIndicatorManager.h>

//Models
#import <WMF/WMFLocationSearchResults.h>
#import <WMF/MWKLocationSearchResult.h>

#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Fetcher Implementation

@interface WMFLocationSearchFetcher ()

@property (nonatomic, strong) WMFSession *session;

@end

NSString *const WMFLocationSearchErrorDomain = @"org.wikimedia.location.search";

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
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:location.coordinate radius:1000 identifier:@""];
    [self fetchArticlesWithSiteURL:siteURL inRegion:region matchingSearchTerm:nil sortStyle:WMFLocationSearchSortStyleNone resultLimit:resultLimit completion:completion failure:failure];
}

- (void)fetchArticlesWithSiteURL:(NSURL *)siteURL
                        inRegion:(CLCircularRegion *)region
              matchingSearchTerm:(nullable NSString *)searchTerm
                       sortStyle:(WMFLocationSearchSortStyle)sortStyle
                     resultLimit:(NSUInteger)resultLimit
                      completion:(void (^)(WMFLocationSearchResults *results))completion
                         failure:(void (^)(NSError *error))failure {

    NSDictionary *params = [self params:region searchTerm:searchTerm resultLimit:resultLimit sortStyle:sortStyle];

    NSURL *url = [[WMFConfiguration.current mediaWikiAPIURLComponentsForHost:siteURL.host withQueryParameters:params] URL];

    assert(url);

    [self.session getJSONDictionaryFromURL:url
                               ignoreCache:YES
                         completionHandler:^(NSDictionary<NSString *, id> *_Nullable result, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
                             NSError *noResultsError = [NSError errorWithDomain:WMFLocationSearchErrorDomain code:WMFLocationSearchErrorCodeNoResults userInfo:@{NSLocalizedDescriptionKey: WMFLocalizedStringWithDefaultValue(@"empty-no-search-results-message", nil, nil, @"No results found", @"Shown when there are no search results")}];

                             if (error) {
                                 if (![[error domain] isEqualToString:NSURLErrorDomain]) {
                                     error = noResultsError;
                                 }
                                 failure(error);
                                 return;
                             }

                             if (response.statusCode == 304) {
                                 NSError *error = [NSError wmf_errorWithType:WMFErrorTypeNoNewData userInfo:nil];
                                 failure(error);
                                 return;
                             }

                             NSDictionary *pages = [result valueForKeyPath:@"query.pages"];

                             if (!pages) {
                                 failure(noResultsError);
                                 return;
                             }

                             if (![pages isKindOfClass:[NSDictionary class]]) {
                                 NSError *error = [NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType userInfo:nil];
                                 failure(error);
                                 return;
                             }

                             NSArray *JSONDictionaries = [pages.allValues wmf_select:^BOOL(id _Nonnull maybeJSONDictionary) {
                                 return [maybeJSONDictionary isKindOfClass:[NSDictionary class]];
                             }];

                             NSError *serializerError = nil;
                             NSArray<MWKLocationSearchResult *> *results = [MTLJSONAdapter modelsOfClass:[MWKLocationSearchResult class] fromJSONArray:JSONDictionaries error:&serializerError];
                             if (serializerError) {
                                 failure(serializerError);
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
