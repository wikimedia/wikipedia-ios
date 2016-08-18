#import "WMFArticlePreviewFetcher.h"
#import "Wikipedia-Swift.h"

#import "UIScreen+WMFImageWidth.h"

// Networking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "AFHTTPSessionManager+WMFDesktopRetry.h"
#import "WMFMantleJSONResponseSerializer.h"
#import <Mantle/Mantle.h>
#import "WMFNumberOfExtractCharacters.h"
#import "NSDictionary+WMFCommonParams.h"
#import "WMFNetworkUtilities.h"
#import "WMFBaseRequestSerializer.h"

//Models
#import "MWKSearchResult.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Internal Class Declarations

@interface WMFArticlePreviewRequestParameters : NSObject

@property (nonatomic, strong) NSArray<NSURL *> *articleURLs;
@property (nonatomic, assign) NSUInteger extractLength;
@property (nonatomic, assign) NSUInteger thumbnailWidth;

@end

@interface WMFArticlePreviewRequestSerializer : WMFBaseRequestSerializer

@end

#pragma mark - Fetcher Implementation

@interface WMFArticlePreviewFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager *operationManager;

@end

@implementation WMFArticlePreviewFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.requestSerializer = [WMFArticlePreviewRequestSerializer serializer];
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

- (AnyPromise *)fetchArticlePreviewResultsForArticleURLs:(NSArray<NSURL *> *)articleURLs
                                                 siteURL:(NSURL *)siteURL {
    return [self fetchArticlePreviewResultsForArticleURLs:articleURLs
                                                  siteURL:siteURL
                                            extractLength:WMFNumberOfExtractCharacters
                                           thumbnailWidth:[[UIScreen mainScreen] wmf_leadImageWidthForScale].unsignedIntegerValue];
}

- (AnyPromise *)fetchArticlePreviewResultsForArticleURLs:(NSArray<NSURL *> *)articleURLs
                                                 siteURL:(NSURL *)siteURL
                                           extractLength:(NSUInteger)extractLength
                                          thumbnailWidth:(NSUInteger)thumbnailWidth {
    WMFArticlePreviewRequestParameters *params = [WMFArticlePreviewRequestParameters new];
    params.articleURLs = articleURLs;
    params.extractLength = extractLength;
    params.thumbnailWidth = thumbnailWidth;

    @weakify(self);
    return [self.operationManager wmf_GETAndRetryWithURL:siteURL parameters:params]
        .thenInBackground(^id(NSArray<MWKSearchResult *> *unsortedPreviews) {
            @strongify(self);
            if (!self) {
                return [NSError cancelledError];
            }
        WMF_TECH_DEBT_TODO(handle case where no preview is retrieved for url)
        return [articleURLs wmf_mapAndRejectNil:^(NSURL *articleURL) {
            MWKSearchResult *matchingPreview = [unsortedPreviews bk_match:^BOOL(MWKSearchResult *preview) {
                return [preview.displayTitle isEqualToString:articleURL.wmf_title];
            }];
            if (!matchingPreview) {
                DDLogWarn(@"Couldn't find requested preview for %@. Returned previews: %@", articleURL, unsortedPreviews);
            }
            return matchingPreview;
        }];
        });
}

@end

#pragma mark - Internal Class Implementations

@implementation WMFArticlePreviewRequestParameters

- (instancetype)init {
    self = [super init];
    if (self) {
        _articleURLs = @[];
        _extractLength = WMFNumberOfExtractCharacters;
        _thumbnailWidth = [[UIScreen mainScreen] wmf_leadImageWidthForScale].unsignedIntegerValue;
    }
    return self;
}

@end

#pragma mark - Request Serializer

@implementation WMFArticlePreviewRequestSerializer

- (nullable NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                                        withParameters:(nullable id)parameters
                                                 error:(NSError *__autoreleasing *)error {
    NSDictionary *serializedParams = [self serializedParams:(WMFArticlePreviewRequestParameters *)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary *)serializedParams:(WMFArticlePreviewRequestParameters *)params {
    NSMutableDictionary *baseParams =
        [NSMutableDictionary wmf_titlePreviewRequestParametersWithExtractLength:params.extractLength
                                                                     imageWidth:@(params.thumbnailWidth)];
    [baseParams setValuesForKeysWithDictionary:@{
        @"titles" : [self barSeparatedTitlesStringFromURLs:params.articleURLs],
        @"pilimit" : @(params.articleURLs.count)
    }];
    if (params.extractLength > 0) {
        baseParams[@"exlimit"] = @(params.articleURLs.count);
    }
    return baseParams;
}

- (NSString *)barSeparatedTitlesStringFromURLs:(NSArray<NSURL *> *)URLs {
    return WMFJoinedPropertyParameters([URLs bk_map:^NSString *(NSURL *URL) {
        return URL.wmf_title;
    }]);
}

@end

NS_ASSUME_NONNULL_END
