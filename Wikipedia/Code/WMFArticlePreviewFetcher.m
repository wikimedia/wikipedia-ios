#import <WMF/WMFArticlePreviewFetcher.h>
#import <Mantle/Mantle.h>
#import <WMF/WMF-Swift.h>
#import <WMF/WMFLegacySerializer.h>

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

@implementation WMFArticlePreviewFetcher

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
    
    NSMutableDictionary *params =
    [NSMutableDictionary wmf_titlePreviewRequestParametersWithExtractLength:extractLength
                                                                 imageWidth:@(thumbnailWidth)];
    NSString *titles = WMFJoinedPropertyParameters([articleURLs wmf_map:^NSString *(NSURL *URL) {
        return URL.wmf_title;
    }]);
    [params setValuesForKeysWithDictionary:@{@"titles": titles, @"pilimit": @(articleURLs.count)}];
    
    params[@"prop"] = [params[@"prop"] stringByAppendingString:@"|coordinates"];
    
    if (extractLength > 0) {
        params[@"exlimit"] = @(articleURLs.count);
    }
 
    @weakify(self);
    NSURLComponents *components = [self.configuration mediaWikiAPIURLComponentsForHost:siteURL.host withQueryParameters:params];
    [self.session getJSONDictionaryFromURL:components.URL ignoreCache:NO completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        @strongify(self);
        if (!self) {
            failure([NSError wmf_cancelledError]);
            return;
        }
        if (error) {
            failure(error);
            return;
        }
        
        NSError *jsonError = nil;
        NSArray<MWKSearchResult *> *unsortedPreviews = [WMFLegacySerializer modelsOfClass:[MWKSearchResult class] fromArrayForKeyPath:@"query.pages" inJSONDictionary:result error:&jsonError];
        if (jsonError) {
            failure(jsonError);
            return;
        }

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

NS_ASSUME_NONNULL_END
