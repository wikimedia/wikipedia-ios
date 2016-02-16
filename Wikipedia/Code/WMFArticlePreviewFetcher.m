#import "WMFArticlePreviewFetcher.h"
#import "Wikipedia-Swift.h"

#import "UIScreen+WMFImageWidth.h"

// Networking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
#import "WMFMantleJSONResponseSerializer.h"
#import <Mantle/Mantle.h>
#import "WMFNumberOfExtractCharacters.h"
#import "NSDictionary+WMFCommonParams.h"
#import "WMFNetworkUtilities.h"

//Models
#import "MWKSearchResult.h"
#import "MWKTitle.h"


NS_ASSUME_NONNULL_BEGIN

#pragma mark - Internal Class Declarations

@interface WMFArticlePreviewRequestParameters : NSObject

@property (nonatomic, strong) NSArray<MWKTitle*>* titles;
@property (nonatomic, assign) NSUInteger extractLength;
@property (nonatomic, assign) NSUInteger thumbnailWidth;

@end

@interface WMFArticlePreviewRequestSerializer : AFHTTPRequestSerializer

@end

#pragma mark - Fetcher Implementation

@interface WMFArticlePreviewFetcher ()

@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@end

@implementation WMFArticlePreviewFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.requestSerializer  = [WMFArticlePreviewRequestSerializer serializer];
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

- (AnyPromise*)fetchArticlePreviewResultsForTitles:(NSArray<MWKTitle*>*)titles
                                              site:(MWKSite*)site {
    return [self fetchArticlePreviewResultsForTitles:titles
                                                site:site
                                       extractLength:WMFNumberOfExtractCharacters
                                      thumbnailWidth:[[UIScreen mainScreen] wmf_leadImageWidthForScale].unsignedIntegerValue];
}

- (AnyPromise*)fetchArticlePreviewResultsForTitles:(NSArray<MWKTitle*>*)titles
                                              site:(MWKSite*)site
                                     extractLength:(NSUInteger)extractLength
                                    thumbnailWidth:(NSUInteger)thumbnailWidth {
    WMFArticlePreviewRequestParameters* params = [WMFArticlePreviewRequestParameters new];
    params.titles         = titles;
    params.extractLength  = extractLength;
    params.thumbnailWidth = thumbnailWidth;

    @weakify(self);
    return [self.operationManager wmf_GETWithSite:site parameters:params]
           .thenInBackground(^id (NSArray<MWKSearchResult*>* unsortedPreviews) {
        @strongify(self);
        if (!self) {
            return [NSError cancelledError];
        }
        WMF_TECH_DEBT_TODO(handle case where no preview is retrieved for title)
        return [titles wmf_mapAndRejectNil:^(MWKTitle* title) {
            MWKSearchResult* matchingPreview = [unsortedPreviews bk_match:^BOOL (MWKSearchResult* preview){
                return [preview.displayTitle isEqualToString:title.text];
            }];
            NSAssert(matchingPreview, @"Couldn't find requested preview for %@. Returned previews: %@", title, unsortedPreviews);
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
        _titles         = @[];
        _extractLength  = WMFNumberOfExtractCharacters;
        _thumbnailWidth = [[UIScreen mainScreen] wmf_leadImageWidthForScale].unsignedIntegerValue;
    }
    return self;
}

@end

#pragma mark - Request Serializer

@implementation WMFArticlePreviewRequestSerializer

- (nullable NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                                       withParameters:(nullable id)parameters
                                                error:(NSError* __autoreleasing*)error {
    NSDictionary* serializedParams = [self serializedParams:(WMFArticlePreviewRequestParameters*)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary*)serializedParams:(WMFArticlePreviewRequestParameters*)params {
    NSMutableDictionary* baseParams =
        [NSMutableDictionary wmf_titlePreviewRequestParametersWithExtractLength:params.extractLength
                                                                     imageWidth:@(params.thumbnailWidth)];
    [baseParams setValuesForKeysWithDictionary:@{
         @"titles":[self barSeparatedTitlesStringFromTitles:params.titles],
         @"pilimit": @(params.titles.count)
     }];
    if (params.extractLength > 0) {
        baseParams[@"exlimit"] = @(params.titles.count);
    }
    return baseParams;
}

- (NSString*)barSeparatedTitlesStringFromTitles:(NSArray<MWKTitle*>*)titles {
    return WMFJoinedPropertyParameters([titles bk_map:^NSString*(MWKTitle* title) {
        return title.text;
    }]);
}

@end

NS_ASSUME_NONNULL_END
