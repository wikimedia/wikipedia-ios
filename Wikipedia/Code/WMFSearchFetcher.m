#import "WMFSearchFetcher_Testing.h"
#import "WMFSearchResults_Internal.h"
#import "WMFSearchResults+ResponseSerializer.h"
@import WMF;

NS_ASSUME_NONNULL_BEGIN

NSUInteger const WMFMaxSearchResultLimit = 24;

#pragma mark - Internal Class Declarations

@interface WMFSearchRequestParameters : NSObject
@property (nonatomic, strong) NSString *searchTerm;
@property (nonatomic, assign) NSUInteger numberOfResults;
@property (nonatomic, assign) BOOL fullTextSearch;

@end

@interface WMFSearchRequestSerializer : WMFBaseRequestSerializer
@end

#pragma mark - Fetcher Implementation

@implementation WMFSearchFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.requestSerializer = [WMFSearchRequestSerializer serializer];
        manager.responseSerializer = [WMFSearchResults responseSerializer];
        self.operationManager = manager;
    }
    return self;
}

- (void)dealloc {
    [self.operationManager invalidateSessionCancelingTasks:YES];
}

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
           appendToPreviousResults:(nullable WMFSearchResults *)results
                           failure:(WMFErrorHandler)failure
                           success:(WMFSearchResultsHandler)success {
    [self fetchArticlesForSearchTerm:searchTerm siteURL:siteURL resultLimit:resultLimit fullTextSearch:fullTextSearch appendToPreviousResults:results useDesktopURL:NO failure:failure success:success];
}

- (void)fetchArticlesForSearchTerm:(NSString *)searchTerm
                           siteURL:(NSURL *)siteURL
                       resultLimit:(NSUInteger)resultLimit
                    fullTextSearch:(BOOL)fullTextSearch
           appendToPreviousResults:(nullable WMFSearchResults *)previousResults
                     useDesktopURL:(BOOL)useDeskTopURL
                           failure:(WMFErrorHandler)failure
                           success:(WMFSearchResultsHandler)success {
    if (!siteURL) {
        siteURL = [NSURL wmf_URLWithDefaultSiteAndCurrentLocale];
    }

    if (!siteURL) {
        failure([NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters userInfo:nil]);
        return;
    }

    NSURL *url = useDeskTopURL ? [NSURL wmf_desktopAPIURLForURL:siteURL] : [NSURL wmf_mobileAPIURLForURL:siteURL];

    WMFSearchRequestParameters *params = [WMFSearchRequestParameters new];
    params.searchTerm = searchTerm;
    params.numberOfResults = resultLimit;
    params.fullTextSearch = fullTextSearch;

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [self.operationManager GET:url.absoluteString
        parameters:params
        progress:NULL
        success:^(NSURLSessionDataTask *operation, id response) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            WMFSearchResults *searchResults = response;
            searchResults.searchTerm = searchTerm;

            if (!previousResults) {
                success(searchResults);
                return;
            }

            [previousResults mergeValuesForKeysFromModel:searchResults];

            success(previousResults);
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            failure(error);
        }];
}

@end

#pragma mark - Internal Class Implementations

@implementation WMFSearchRequestParameters

- (void)setNumberOfResults:(NSUInteger)numberOfResults {
    if (numberOfResults > WMFMaxSearchResultLimit) {
        DDLogError(@"Illegal attempt to request %lu articles, limiting to %lu.",
                   (unsigned long)numberOfResults, (unsigned long)WMFMaxSearchResultLimit);
        numberOfResults = WMFMaxSearchResultLimit;
    }
    _numberOfResults = numberOfResults;
}

@end

#pragma mark - Request Serializer

@implementation WMFSearchRequestSerializer

- (nullable NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                                        withParameters:(nullable id)parameters
                                                 error:(NSError *__autoreleasing *)error {
    NSDictionary *serializedParams = [self serializedParams:(WMFSearchRequestParameters *)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary *)serializedParams:(WMFSearchRequestParameters *)params {
    NSNumber *numResults = @(params.numberOfResults);

    if (!params.fullTextSearch) {
        return @{
            @"action": @"query",
            @"generator": @"prefixsearch",
            @"gpssearch": params.searchTerm,
            @"gpsnamespace": @0,
            @"gpslimit": numResults,
            @"prop": @"description|pageprops|pageimages|revisions|coordinates",
            @"coprop": @"type|dim",
            @"piprop": @"thumbnail",
            //@"pilicense": @"any",
            @"ppprop": @"displaytitle|disambiguation",
            @"pithumbsize": [[UIScreen mainScreen] wmf_listThumbnailWidthForScale],
            @"pilimit": numResults,
            //@"rrvlimit": @(1),
            @"rvprop": @"ids",
            // -- Parameters causing prefix search to efficiently return suggestion.
            @"list": @"search",
            @"srsearch": params.searchTerm,
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
        return @{
            @"action": @"query",
            @"prop": @"description|pageprops|pageimages|revisions|coordinates",
            @"coprop": @"type|dim",
            @"ppprop": @"displaytitle|disambiguation",
            @"generator": @"search",
            @"gsrsearch": params.searchTerm,
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
}

@end

NS_ASSUME_NONNULL_END
