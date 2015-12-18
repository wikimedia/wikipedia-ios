
#import "WMFTitlesSearchFetcher.h"

//AFNetworking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
#import "WMFMantleJSONResponseSerializer.h"
#import <Mantle/Mantle.h>

//Promises
#import "Wikipedia-Swift.h"

//Models
#import "WMFTitlesSearchResults.h"
#import "MWKSearchResult.h"
#import "MWKTitle.h"

#import "NSDictionary+WMFCommonParams.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Internal Class Declarations

@interface WMFTitlesSearchRequestParameters : NSObject

@property (nonatomic, strong) NSArray<MWKTitle*>* titles;

@end

@interface WMFTitlesSearchRequestSerializer : AFHTTPRequestSerializer

@end

#pragma mark - Fetcher Implementation

@interface WMFTitlesSearchFetcher ()

@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@end

@implementation WMFTitlesSearchFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.requestSerializer  = [WMFTitlesSearchRequestSerializer serializer];
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

- (AnyPromise*)fetchSearchResultsForTitles:(NSArray<MWKTitle*>*)titles site:(MWKSite*)site {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        WMFTitlesSearchRequestParameters* params = [WMFTitlesSearchRequestParameters new];
        params.titles = titles;
        
        [self.operationManager wmf_GETWithSite:site
                                    parameters:params
                                         retry:NULL
                                       success:^(AFHTTPRequestOperation* operation, id responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve([[WMFTitlesSearchResults alloc] initWithTitles:titles results:responseObject]);
        }
                                       failure:^(AFHTTPRequestOperation* operation, NSError* error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }];
    }];
}

@end

#pragma mark - Internal Class Implementations

@implementation WMFTitlesSearchRequestParameters

@end

#pragma mark - Request Serializer

@implementation WMFTitlesSearchRequestSerializer

- (nullable NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                                       withParameters:(nullable id)parameters
                                                error:(NSError* __autoreleasing*)error {
    NSDictionary* serializedParams = [self serializedParams:(WMFTitlesSearchRequestParameters*)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary*)serializedParams:(WMFTitlesSearchRequestParameters*)params {
    NSMutableDictionary* baseParams = [NSMutableDictionary wmf_titlePreviewRequestParameters];
    [baseParams setValuesForKeysWithDictionary:@{
         @"titles": [self barSeparatedTitlesStringFromTitles:params.titles],
         @"exlimit": @(params.titles.count),
         @"pilimit": @(params.titles.count)
     }];
    return baseParams;
}

- (NSString*)barSeparatedTitlesStringFromTitles:(NSArray<MWKTitle*>*)titles {
    return [[titles bk_map:^NSString*(MWKTitle* title) {
        return title.text;
    }] componentsJoinedByString:@"|"];
}

@end

NS_ASSUME_NONNULL_END
