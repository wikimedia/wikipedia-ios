#import "WMFSearchFetcher_Testing.h"
#import "WMFSearchResults_Internal.h"
@import WMF;

NS_ASSUME_NONNULL_BEGIN

NSUInteger const WMFMaxSearchResultLimit = 24;

#pragma mark - Fetcher Implementation

@implementation WMFSearchFetcher

- (void)fetchArticlesForSearchTerm:(NSString *)searchTerm
                           siteURL:(NSURL *)siteURL
                       resultLimit:(NSUInteger)resultLimit
                           failure:(WMFErrorHandler)failure
                           success:(WMFSearchResultsHandler)success {
    [self fetchArticlesForSearchTerm:searchTerm siteURL:siteURL resultLimit:resultLimit fullTextSearch:NO appendToPreviousResults:nil failure:failure success:success];
}

- (void)fetchArticlesForSearchTerm:(NSString *)searchTerm
                           siteURL:(NSURL *)siteURL
                       resultLimit:(NSUInteger)resultLimit
                    fullTextSearch:(BOOL)fullTextSearch
           appendToPreviousResults:(nullable WMFSearchResults *)previousResults
                           failure:(WMFErrorHandler)failure
                           success:(WMFSearchResultsHandler)success {
    if (!siteURL) {
        siteURL = [NSURL wmf_URLWithDefaultSiteAndCurrentLocale];
    }

    if (!siteURL) {
        failure([WMFFetcher invalidParametersError]);
        return;
    }

    if (resultLimit > WMFMaxSearchResultLimit) {
        DDLogWarn(@"Illegal attempt to request %lu articles, limiting to %lu.",
                   (unsigned long)resultLimit, (unsigned long)WMFMaxSearchResultLimit);
        resultLimit = WMFMaxSearchResultLimit;
    }

    NSNumber *numResults = @(resultLimit);

    NSDictionary *params = nil;
    if (!fullTextSearch) {
        params = @{
                   @"action": @"query",
                   @"generator": @"prefixsearch",
                   @"gpssearch": searchTerm,
                   @"gpsnamespace": @0,
                   @"gpslimit": numResults,
                   @"prop": @"description|pageprops|pageimages|revisions|coordinates",
                   @"coprop": @"type|dim",
                   @"piprop": @"thumbnail",
                   //@"pilicense": @"any",
                   @"ppprop": @"displaytitle",
                   @"pithumbsize": [[UIScreen mainScreen] wmf_listThumbnailWidthForScale],
                   @"pilimit": numResults,
                   //@"rrvlimit": @(1),
                   @"rvprop": @"ids",
                   // -- Parameters causing prefix search to efficiently return suggestion.
                   @"list": @"search",
                   @"srsearch": searchTerm,
                   @"srnamespace": @0,
                   @"srwhat": @"text",
                   @"srinfo": @"suggestion",
                   @"srprop": @"",
                   @"sroffset": @0,
                   @"srlimit": @1,
                   @"redirects": @1,
                   // --
                   @"continue": @"",
                   @"format": @"json"
                   };
    } else {
        params = @{
                 @"action": @"query",
                 @"prop": @"description|pageprops|pageimages|revisions|coordinates",
                 @"coprop": @"type|dim",
                 @"ppprop": @"displaytitle",
                 @"generator": @"search",
                 @"gsrsearch": searchTerm,
                 @"gsrnamespace": @0,
                 @"gsrwhat": @"text",
                 @"gsrinfo": @"",
                 @"gsrprop": @"redirecttitle",
                 @"gsroffset": @0,
                 @"gsrlimit": numResults,
                 @"piprop": @"thumbnail",
                 //@"pilicense": @"any",
                 @"pithumbsize": [[UIScreen mainScreen] wmf_listThumbnailWidthForScale],
                 @"pilimit": numResults,
                 //@"rrvlimit": @(1),
                 @"rvprop": @"ids",
                 @"continue": @"",
                 @"format": @"json",
                 @"redirects": @1,
                 };
    }

    [self performSearchRequestForSearchTerm:searchTerm url:siteURL queryParameters:params appendToPreviousResults:previousResults failure:failure success:success];
}

- (void)performSearchRequestForSearchTerm:(NSString *)searchTerm url:(NSURL *)url queryParameters:(NSDictionary *)queryParameters appendToPreviousResults:(nullable WMFSearchResults *)previousResults failure:(WMFErrorHandler)failure success:(WMFSearchResultsHandler)success {
    [self performMediaWikiAPIGETForURL:url
                   withQueryParameters:queryParameters
                     completionHandler:^(NSDictionary<NSString *, id> *_Nullable result, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {                         if (error) {
                             failure(error);
                             return;
                         }

                         NSDictionary *query = [result objectForKey:@"query"];
                         if (!query) {
                             WMFSearchResults *returnResults = previousResults == nil ? [[WMFSearchResults alloc] initWithLanguageVariantCode:url.wmf_languageVariantCode] : previousResults;
                             success(returnResults);
                             return;
                         }

                         NSError *mantleError = nil;
                         WMFSearchResults *searchResults = [MTLJSONAdapter modelOfClass:[WMFSearchResults class] fromJSONDictionary:query languageVariantCode:url.wmf_languageVariantCode error:&mantleError];
                         if (mantleError) {
                             failure(mantleError);
                             return;
                         }
                         searchResults.searchTerm = searchTerm;

                         if (!previousResults) {
                             success(searchResults);
                             return;
                         }

                         [previousResults mergeValuesForKeysFromModel:searchResults];

                         success(previousResults);
                     }];
}

- (void)fetchFilesForSearchTerm:(NSString *)searchTerm
                    resultLimit:(NSUInteger)resultLimit
                 fullTextSearch:(BOOL)fullTextSearch
        appendToPreviousResults:(nullable WMFSearchResults *)results
                        failure:(WMFErrorHandler)failure
                        success:(WMFSearchResultsHandler)success {
    NSURL *siteURL = [NSURL URLWithString:@"//commons.wikimedia.org"]; // Only the host of the URL is needed
    NSURL *url = [self.configuration mediaWikiAPIURLForURL:siteURL withQueryParameters:nil];
    if (!url) {
        failure(WMFFetcher.invalidParametersError);
        return;
    }
    if (resultLimit > WMFMaxSearchResultLimit) {
        DDLogWarn(@"Illegal attempt to request %lu articles, limiting to %lu.",
                   (unsigned long)resultLimit, (unsigned long)WMFMaxSearchResultLimit);
        resultLimit = WMFMaxSearchResultLimit;
    }

    NSNumber *namespace = @6;
    NSNumber *numResults = @(resultLimit);
    NSDictionary *params = nil;
    if (!fullTextSearch) {
        params = @{
                   @"action": @"query",
                   @"generator": @"prefixsearch",
                   @"gpssearch": searchTerm,
                   @"gpsnamespace": namespace,
                   @"gpslimit": numResults,
                   @"prop": @"description|pageprops|pageimages|revisions",
                   @"coprop": @"type|dim",
                   @"piprop": @"thumbnail",
                   @"ppprop": @"displaytitle",
                   @"pithumbsize": [[UIScreen mainScreen] wmf_listThumbnailWidthForScale],
                   @"pilimit": numResults,
                   @"rvprop": @"ids",
                   // -- Parameters causing prefix search to efficiently return suggestion.
                   @"list": @"search",
                   @"srsearch": searchTerm,
                   @"srnamespace": namespace,
                   @"srwhat": @"text",
                   @"srinfo": @"suggestion",
                   @"srprop": @"",
                   @"sroffset": @0,
                   @"srlimit": @1,
                   @"redirects": @1,
                   // --
                   @"continue": @"",
                   @"format": @"json"
                   };
    } else {
        params = @{
                   @"action": @"query",
                   @"prop": @"description|pageprops|pageimages|revisions",
                   @"coprop": @"type|dim",
                   @"ppprop": @"displaytitle",
                   @"generator": @"search",
                   @"gsrsearch": searchTerm,
                   @"gsrnamespace": namespace,
                   @"gsrwhat": @"text",
                   @"gsrinfo": @"",
                   @"gsrprop": @"redirecttitle",
                   @"gsroffset": @0,
                   @"gsrlimit": numResults,
                   @"piprop": @"thumbnail",
                   @"pithumbsize": [[UIScreen mainScreen] wmf_listThumbnailWidthForScale],
                   @"pilimit": numResults,
                   @"rvprop": @"ids",
                   @"continue": @"",
                   @"format": @"json",
                   @"redirects": @1,
                   };
    }
    [self performSearchRequestForSearchTerm:searchTerm url:url queryParameters:params appendToPreviousResults:results failure:failure success:success];
}

@end

NS_ASSUME_NONNULL_END
