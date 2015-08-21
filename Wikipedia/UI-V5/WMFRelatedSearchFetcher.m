
#import "WMFRelatedSearchFetcher.h"

//AFNetworking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "WMFSearchResponseSerializer.h"
#import <Mantle/Mantle.h>

//Promises
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

//Models
#import "WMFRelatedSearchResults.h"
#import "MWKSearchResult.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Internal Class Declarations

@interface WMFRelatedSearchRequestParameters : NSObject
@property (nonatomic, strong) MWKTitle *title;
@property (nonatomic, assign) NSUInteger numberOfResults;
@end

@interface WMFRelatedSearchRequestSerializer : AFHTTPRequestSerializer
@end

#pragma mark - Fetcher Implementation

@interface WMFRelatedSearchFetcher ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@end

@implementation WMFRelatedSearchFetcher

- (instancetype)initWithSearchSite:(MWKSite*)site {
    self = [super init];
    if (self) {
        NSParameterAssert(site);
        self.searchSite = site;
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.requestSerializer  = [WMFRelatedSearchRequestSerializer serializer];
        manager.responseSerializer = [WMFSearchResponseSerializer serializer];
        self.operationManager      = manager;
    }
    return self;
}

- (BOOL)isFetching{
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (AnyPromise*)fetchArticlesRelatedToTitle:(MWKTitle*)title{
    return [self fetchArticlesRelatedToTitle:title useDesktopURL:NO];
}

- (AnyPromise*)fetchArticlesRelatedToTitle:(MWKTitle*)title useDesktopURL:(BOOL)useDeskTopURL {
    
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSURL* url = [self.searchSite apiEndpoint:useDeskTopURL];
        
        WMFRelatedSearchRequestParameters* params = [WMFRelatedSearchRequestParameters new];
        params.title = title;
        params.numberOfResults = self.maximumNumberOfResults;
        
        [self.operationManager GET:url.absoluteString parameters:params success:^(AFHTTPRequestOperation* operation, id response) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            WMFRelatedSearchResults* results = [[WMFRelatedSearchResults alloc] initWithTitle:title results:response];
            resolve(results);
        } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
            if ([url isEqual:[self.searchSite mobileApiEndpoint]] && [error wmf_shouldFallbackToDesktopURLError]) {
                [self fetchArticlesRelatedToTitle:title useDesktopURL:YES];
            } else {
                [[MWNetworkActivityIndicatorManager sharedManager] pop];
                resolve(error);
            }
        }];
    }];
}

@end

#pragma mark - Internal Class Implementations

@implementation WMFRelatedSearchRequestParameters
@end

#pragma mark - Request Serializer

#define LEAD_IMAGE_WIDTH (([UIScreen mainScreen].scale > 1) ? 640 : 320)

@implementation WMFRelatedSearchRequestSerializer

- (NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                              withParameters:(id)parameters
                                       error:(NSError* __autoreleasing*)error {
    
    NSDictionary* serializedParams = [self serializedParams:(WMFRelatedSearchRequestParameters*)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary*)serializedParams:(WMFRelatedSearchRequestParameters*)params {
    NSString* numberOfResults = [NSString stringWithFormat:@"%lu", (unsigned long)params.numberOfResults];
    
    return @{
             @"action": @"query",
             @"prop": @"pageterms|pageimages",
             @"wbptterms": @"description",
             @"generator": @"search",
             @"gsrsearch": [NSString stringWithFormat:@"morelike:%@", params.title.text],
             @"gsrnamespace": @0,
             @"gsrwhat": @"text",
             @"gsrinfo": @"",
             @"gsrprop": @"redirecttitle",
             @"gsroffset": @0,
             @"gsrlimit": numberOfResults,
             @"piprop": @"thumbnail",
             @"pithumbsize": @(LEAD_IMAGE_WIDTH),
             @"pilimit": numberOfResults,
             @"continue": @"",
             @"format": @"json"
             };
}

@end



NS_ASSUME_NONNULL_END
