
#import "WMFArticlePreviewFetcher.h"

//AFNetworking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
#import "WMFMantleJSONResponseSerializer.h"
#import <Mantle/Mantle.h>

//Promises
#import "Wikipedia-Swift.h"

//Models
#import "WMFArticlePreviewResults.h"
#import "MWKSearchResult.h"
#import "MWKTitle.h"

#import "NSDictionary+WMFCommonParams.h"
#import "WMFNetworkUtilities.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Internal Class Declarations

@interface WMFArticlePreviewRequestParameters : NSObject

@property (nonatomic, strong) NSArray<MWKTitle*>* titles;

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

- (AnyPromise*)fetchArticlePreviewResultsForTitles:(NSArray<MWKTitle*>*)titles site:(MWKSite*)site {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        WMFArticlePreviewRequestParameters* params = [WMFArticlePreviewRequestParameters new];
        params.titles = titles;
        
        [self.operationManager wmf_GETWithSite:site
                                    parameters:params
                                         retry:NULL
                                       success:^(AFHTTPRequestOperation* operation, id responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve([[WMFArticlePreviewResults alloc] initWithTitles:titles results:responseObject]);
        }
                                       failure:^(AFHTTPRequestOperation* operation, NSError* error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }];
    }];
}

@end

#pragma mark - Internal Class Implementations

@implementation WMFArticlePreviewRequestParameters

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
    NSMutableDictionary* baseParams = [NSMutableDictionary wmf_titlePreviewRequestParameters];
    [baseParams setValuesForKeysWithDictionary:@{
         @"titles": [self barSeparatedTitlesStringFromTitles:params.titles],
         @"exlimit": @(params.titles.count),
         @"pilimit": @(params.titles.count)
     }];
    return baseParams;
}

- (NSString*)barSeparatedTitlesStringFromTitles:(NSArray<MWKTitle*>*)titles {
    return WMFJoinedPropertyParameters([titles bk_map:^NSString*(MWKTitle* title) {
        return title.text;
    }]);
}

@end

NS_ASSUME_NONNULL_END
