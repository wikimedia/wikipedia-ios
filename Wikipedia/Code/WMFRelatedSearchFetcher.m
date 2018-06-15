#import <WMF/WMFRelatedSearchFetcher.h>
#import <WMF/NSURL+WMFLinkParsing.h>

//AFNetworking
#import <WMF/MWNetworkActivityIndicatorManager.h>
#import <WMF/AFHTTPSessionManager+WMFConfig.h>
#import <WMF/AFHTTPSessionManager+WMFDesktopRetry.h>
#import <WMF/WMFMantleJSONResponseSerializer.h>
@import Mantle;
#import <WMF/WMFBaseRequestSerializer.h>

//Models
#import <WMF/WMFRelatedSearchResults.h>
#import <WMF/MWKSearchResult.h>

#import <WMF/NSDictionary+WMFCommonParams.h>
#import <WMF/WMFLogging.h>

NS_ASSUME_NONNULL_BEGIN

NSUInteger const WMFMaxRelatedSearchResultLimit = 20;

#pragma mark - Internal Class Declarations

@interface WMFRelatedSearchRequestParameters : NSObject
@property (nonatomic, strong) NSURL *articleURL;
@property (nonatomic, assign) NSUInteger numberOfResults;
@end

@interface WMFRelatedSearchRequestSerializer : WMFBaseRequestSerializer
@end

#pragma mark - Fetcher Implementation

@interface WMFRelatedSearchFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager *operationManager;

@end

@implementation WMFRelatedSearchFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.requestSerializer = [WMFRelatedSearchRequestSerializer serializer];
        manager.responseSerializer =
            [WMFMantleJSONResponseSerializer serializerForValuesInDictionaryOfType:[MWKSearchResult class] fromKeypath:@"query.pages" emptyValueForJSONKeypathAllowed:NO];
        self.operationManager = manager;
    }
    return self;
}

- (void)dealloc {
    [self.operationManager invalidateSessionCancelingTasks:YES];
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (void)fetchArticlesRelatedArticleWithURL:(NSURL *)URL
                               resultLimit:(NSUInteger)resultLimit
                           completionBlock:(void (^)(WMFRelatedSearchResults *results))completion
                              failureBlock:(void (^)(NSError *error))failure {

    WMFRelatedSearchRequestParameters *params = [WMFRelatedSearchRequestParameters new];
    params.articleURL = URL;
    params.numberOfResults = resultLimit;

    [self.operationManager wmf_GETAndRetryWithURL:URL
        parameters:params
        retry:NULL
        success:^(NSURLSessionDataTask *operation, id responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            if (completion) {
                completion([[WMFRelatedSearchResults alloc] initWithURL:URL results:responseObject]);
            }
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            if (failure) {
                failure(error);
            }
        }];
}

@end

#pragma mark - Internal Class Implementations

@implementation WMFRelatedSearchRequestParameters

- (void)setNumberOfResults:(NSUInteger)numberOfResults {
    if (numberOfResults > WMFMaxRelatedSearchResultLimit) {
        DDLogError(@"Illegal attempt to request %lu articles, limiting to %lu.",
                   (unsigned long)numberOfResults, (unsigned long)WMFMaxRelatedSearchResultLimit);
        numberOfResults = WMFMaxRelatedSearchResultLimit;
    }
    _numberOfResults = numberOfResults;
}

@end

#pragma mark - Request Serializer

@implementation WMFRelatedSearchRequestSerializer

- (nullable NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                                        withParameters:(nullable id)parameters
                                                 error:(NSError *__autoreleasing *)error {
    NSDictionary *serializedParams = [self serializedParams:(WMFRelatedSearchRequestParameters *)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary *)serializedParams:(WMFRelatedSearchRequestParameters *)params {
    NSNumber *numResults = @(params.numberOfResults);
    NSURL *articleURL = params.articleURL;
    NSString *articleTitle = articleURL.wmf_title;
    NSString *gsrsearch = [NSString stringWithFormat:@"morelike:%@", articleTitle];
    NSMutableDictionary *baseParams = [NSMutableDictionary wmf_titlePreviewRequestParameters];
    [baseParams setValuesForKeysWithDictionary:@{
        @"generator": @"search",
        // search
        @"gsrsearch": gsrsearch,
        @"gsrnamespace": @0,
        @"gsrwhat": @"text",
        @"gsrinfo": @"",
        @"gsrprop": @"redirecttitle",
        @"gsroffset": @0,
        @"gsrlimit": numResults,
        @"ppprop": @"displaytitle",
        // extracts
        @"exlimit": numResults,
        // pageimage
        @"pilimit": numResults,
        //@"pilicense": @"any",
    }];
    return baseParams;
}

@end

NS_ASSUME_NONNULL_END
