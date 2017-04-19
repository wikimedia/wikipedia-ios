#import "WMFRelatedSearchFetcher.h"

//AFNetworking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "AFHTTPSessionManager+WMFDesktopRetry.h"
#import "WMFMantleJSONResponseSerializer.h"
#import <Mantle/Mantle.h>
#import "WMFBaseRequestSerializer.h"

//Models
#import "WMFRelatedSearchResults.h"
#import "MWKSearchResult.h"

#import "NSDictionary+WMFCommonParams.h"

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
            [WMFMantleJSONResponseSerializer serializerForValuesInDictionaryOfType:[MWKSearchResult class]
                                                                       fromKeypath:@"query.pages"];
        self.operationManager = manager;
    }
    return self;
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
    NSMutableDictionary *baseParams = [NSMutableDictionary wmf_titlePreviewRequestParameters];
    [baseParams setValuesForKeysWithDictionary:@{
        @"generator": @"search",
        // search
        @"gsrsearch": [NSString stringWithFormat:@"morelike:%@", params.articleURL.wmf_title],
        @"gsrnamespace": @0,
        @"gsrwhat": @"text",
        @"gsrinfo": @"",
        @"gsrprop": @"redirecttitle",
        @"gsroffset": @0,
        @"gsrlimit": numResults,
        // extracts
        @"exlimit": numResults,
        // pageimage
        @"pilimit": numResults,
        @"pilicense": @"any",
    }];
    return baseParams;
}

@end

NS_ASSUME_NONNULL_END
