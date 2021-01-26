#import <WMF/WMFLocationSearchFetcher.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/WMFLocalization.h>
#import <WMF/UIScreen+WMFImageWidth.h>
#import <WMF/WMFNumberOfExtractCharacters.h>
#import <WMF/WMFLegacySerializer.h>

//Models
#import <WMF/WMFLocationSearchResults.h>
#import <WMF/MWKLocationSearchResult.h>

#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Fetcher Implementation

NSString *const WMFLocationSearchErrorDomain = @"org.wikimedia.location.search";

@implementation WMFLocationSearchFetcher

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

    NSURL *url = [self.configuration mediaWikiAPIURLForURL:siteURL withQueryParameters:params];

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
                                 NSError *error = [WMFFetcher noNewDataError];
                                 failure(error);
                                 return;
                             }

                             NSDictionary *pages = [result valueForKeyPath:@"query.pages"];

                             if (!pages) {
                                 failure(noResultsError);
                                 return;
                             }

                             if (![pages isKindOfClass:[NSDictionary class]]) {
                                 NSError *error = [WMFFetcher unexpectedResponseError];
                                 failure(error);
                                 return;
                             }

                             NSArray *JSONDictionaries = [pages.allValues wmf_select:^BOOL(id _Nonnull maybeJSONDictionary) {
                                 return [maybeJSONDictionary isKindOfClass:[NSDictionary class]];
                             }];

                             NSError *serializerError = nil;
        NSArray<MWKLocationSearchResult *> *results = [MTLJSONAdapter modelsOfClass:[MWKLocationSearchResult class] fromJSONArray:JSONDictionaries languageVariantCode: url.wmf_languageVariantCode error:&serializerError];
                             if (serializerError) {
                                 failure(serializerError);
                                 return;
                             }
                             WMFLocationSearchResults *locationSearchResults = [[WMFLocationSearchResults alloc] initWithSearchSiteURL:siteURL region:region searchTerm:searchTerm results:results];
                             completion(locationSearchResults);
                         }];
}

- (NSDictionary *)params:(CLCircularRegion *)region searchTerm:(nullable NSString *)searchTerm resultLimit:(NSUInteger)numberOfResults sortStyle:(WMFLocationSearchSortStyle)sortStyle {
    if (region.radius >= 10000 || searchTerm || sortStyle != WMFLocationSearchSortStyleNone) {
        NSMutableArray<NSString *> *gsrSearchArray = [NSMutableArray arrayWithCapacity:2];
        if (searchTerm) {
            [gsrSearchArray addObject:searchTerm];
        }
        CLLocationDistance radius = MAX(1, ceil(region.radius));
        NSString *nearcoord = [NSString stringWithFormat:@"nearcoord:%.0fm,%.3f,%.3f", radius, region.center.latitude, region.center.longitude];
        [gsrSearchArray addObject:nearcoord];
        NSString *gsrsearch = [gsrSearchArray componentsJoinedByString:@" "];
        NSMutableDictionary<NSString *, NSObject *> *serializedParams = [NSMutableDictionary dictionaryWithDictionary:@{
            @"action": @"query",
            @"prop": @"coordinates|pageimages|description|pageprops",
            @"coprop": @"type|dim",
            @"colimit": @(numberOfResults),
            @"generator": @"search",
            @"gsrsearch": gsrsearch,
            @"gsrlimit": @(numberOfResults),
            @"piprop": @"thumbnail",
            //@"pilicense": @"any",
            @"pithumbsize": [[UIScreen mainScreen] wmf_nearbyThumbnailWidthForScale],
            @"pilimit": @(numberOfResults),
            @"ppprop": @"displaytitle",
            @"format": @"json",
        }];
        switch (sortStyle) {
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
            [NSString stringWithFormat:@"%f|%f", region.center.latitude, region.center.longitude];
        return @{
            @"action": @"query",
            @"prop": @"coordinates|pageimages|description|pageprops|extracts",
            @"coprop": @"type|dim",
            @"colimit": @(numberOfResults),
            @"pithumbsize": [[UIScreen mainScreen] wmf_nearbyThumbnailWidthForScale],
            @"pilimit": @(numberOfResults),
            //@"pilicense": @"any",
            @"ppprop": @"displaytitle",
            @"generator": @"geosearch",
            @"ggscoord": coords,
            @"codistancefrompoint": coords,
            @"ggsradius": @(region.radius),
            @"ggslimit": @(numberOfResults),
            @"exintro": @YES,
            @"exlimit": @(numberOfResults),
            @"explaintext": @"",
            @"exchars": @(WMFNumberOfExtractCharacters),
            @"format": @"json"
        };
    }
}

@end

NS_ASSUME_NONNULL_END
