#import <WMF/WMFArticlePreviewFetcher.h>
#import <Mantle/Mantle.h>
#import <WMF/WMF-Swift.h>

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

- (void)fetchArticlePreviewResultsForArticleURLs:(NSArray<NSURL *> *)articleURLs
                                         siteURL:(NSURL *)siteURL
                                      completion:(void (^)(NSArray<MWKSearchResult *> *results))completion
                                         failure:(void (^)(NSError *error))failure {
    [self fetchArticlePreviewResultsForArticleURLs:articleURLs siteURL:siteURL extractLength:WMFNumberOfExtractCharacters thumbnailWidth:[[UIScreen mainScreen] wmf_leadImageWidthForScale].unsignedIntegerValue completion:completion failure:failure];
}

- (void)fetchArticlePreviewResultsForArticleURLs:(NSArray<NSURL *> *)articleURLs
                                         siteURL:(NSURL *)siteURL
                                   extractLength:(NSUInteger)extractLength
                                  thumbnailWidth:(NSUInteger)thumbnailWidth
                                      completion:(void (^)(NSArray<MWKSearchResult *> *results))completion
                                         failure:(void (^)(NSError *error))failure {

    WMFArticlePreviewRequestParameters *params = [WMFArticlePreviewRequestParameters new];
    params.articleURLs = articleURLs;
    params.extractLength = extractLength;
    params.thumbnailWidth = thumbnailWidth;

    @weakify(self);
    [self.operationManager wmf_GETAndRetryWithURL:siteURL
        parameters:params
        retry:NULL
        success:^(NSURLSessionDataTask *operation, NSArray<MWKSearchResult *> *unsortedPreviews) {
            @strongify(self);
            if (!self) {
                failure([NSError wmf_cancelledError]);
                return;
            }
        WMF_TECH_DEBT_TODO(handle case where no preview is retrieved for url)
        NSArray *results = [articleURLs wmf_mapAndRejectNil:^(NSURL *articleURL) {
            MWKSearchResult *matchingPreview = [unsortedPreviews wmf_match:^BOOL(MWKSearchResult *preview) {
                return [preview.displayTitle isEqualToString:articleURL.wmf_title];
            }];
            if (!matchingPreview) {
                DDLogWarn(@"Couldn't find requested preview for %@. Returned previews: %@", articleURL, unsortedPreviews);
            }
            return matchingPreview;
        }];

        completion(results);

        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            failure(error);
        }];
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
        @"titles": [self barSeparatedTitlesStringFromURLs:params.articleURLs],
        @"pilimit": @(params.articleURLs.count),
    }];

    baseParams[@"prop"] = [baseParams[@"prop"] stringByAppendingString:@"|coordinates"];

    if (params.extractLength > 0) {
        baseParams[@"exlimit"] = @(params.articleURLs.count);
    }
    return baseParams;
}

- (NSString *)barSeparatedTitlesStringFromURLs:(NSArray<NSURL *> *)URLs {
    return WMFJoinedPropertyParameters([URLs wmf_map:^NSString *(NSURL *URL) {
        return URL.wmf_title;
    }]);
}

@end

NS_ASSUME_NONNULL_END
