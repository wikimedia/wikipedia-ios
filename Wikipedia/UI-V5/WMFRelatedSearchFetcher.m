
#import "WMFRelatedSearchFetcher.h"

//AFNetworking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "WMFMantleJSONResponseSerializer.h"
#import <Mantle/Mantle.h>

//Promises
#import "Wikipedia-Swift.h"

//Models
#import "WMFRelatedSearchResults.h"
#import "MWKRelatedSearchResult.h"
#import "MWKTitle.h"

NS_ASSUME_NONNULL_BEGIN

NSUInteger const WMFMaxRelatedSearchResultLimit = 20;

#pragma mark - Internal Class Declarations

@interface WMFRelatedSearchRequestParameters : NSObject
@property (nonatomic, strong) MWKTitle* title;
@property (nonatomic, assign) NSUInteger numberOfResults;
@property (nonatomic, assign) NSUInteger numberOfExtractCharacters;

@end

@interface WMFRelatedSearchRequestSerializer : AFHTTPRequestSerializer
@end

#pragma mark - Fetcher Implementation

@interface WMFRelatedSearchFetcher ()

@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@end

@implementation WMFRelatedSearchFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.requestSerializer  = [WMFRelatedSearchRequestSerializer serializer];
        manager.responseSerializer =
            [WMFMantleJSONResponseSerializer serializerForValuesInDictionaryOfType:[MWKRelatedSearchResult class]
                                                                       fromKeypath:@"query.pages"];
        self.operationManager = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (AnyPromise*)fetchArticlesRelatedToTitle:(MWKTitle*)title
                  numberOfExtactCharacters:(NSUInteger)extractChars
                               resultLimit:(NSUInteger)resultLimit {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self fetchArticlesRelatedToTitle:title
                 numberOfExtactCharacters:extractChars
                              resultLimit:resultLimit
                            useDesktopURL:NO
                                 resolver:resolve];
    }];
}

- (void)fetchArticlesRelatedToTitle:(MWKTitle*)title
           numberOfExtactCharacters:(NSUInteger)extractChars
                        resultLimit:(NSUInteger)resultLimit
                      useDesktopURL:(BOOL)useDeskTopURL
                           resolver:(PMKResolver)resolve {
    MWKSite* searchSite = title.site;
    NSURL* url          = [searchSite apiEndpoint:useDeskTopURL];

    WMFRelatedSearchRequestParameters* params = [WMFRelatedSearchRequestParameters new];
    params.title                     = title;
    params.numberOfResults           = resultLimit;
    params.numberOfExtractCharacters = extractChars;

    [self.operationManager GET:url.absoluteString
                    parameters:params
                       success:^(AFHTTPRequestOperation* operation, id response) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        resolve([[WMFRelatedSearchResults alloc] initWithTitle:title results:response]);
    }
                       failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        if ([url isEqual:[searchSite mobileApiEndpoint]] && [error wmf_shouldFallbackToDesktopURLError]) {
            [self fetchArticlesRelatedToTitle:title
                     numberOfExtactCharacters:extractChars
                                  resultLimit:resultLimit
                                useDesktopURL:YES
                                     resolver:resolve];
        } else {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }
    }];
}

@end

#pragma mark - Internal Class Implementations

@implementation WMFRelatedSearchRequestParameters

- (void)setNumberOfResults:(NSUInteger)numberOfResults {
    if (numberOfResults > WMFMaxRelatedSearchResultLimit) {
        DDLogError(@"Illegal attempt to request %lu articles, limiting to %lu.",
                   numberOfResults, WMFMaxRelatedSearchResultLimit);
        numberOfResults = WMFMaxRelatedSearchResultLimit;
    }
    _numberOfResults = numberOfResults;
}

@end

#pragma mark - Request Serializer

#define LEAD_IMAGE_WIDTH (([UIScreen mainScreen].scale > 1) ? 640 : 320)

@implementation WMFRelatedSearchRequestSerializer

- (nullable NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                                       withParameters:(nullable id)parameters
                                                error:(NSError* __autoreleasing*)error {
    NSDictionary* serializedParams = [self serializedParams:(WMFRelatedSearchRequestParameters*)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary*)serializedParams:(WMFRelatedSearchRequestParameters*)params {
    NSNumber* numResults = @(params.numberOfResults);
    return @{
               @"continue": @"",
               @"format": @"json",
               @"action": @"query",
               @"prop": @"extracts|pageterms|pageimages",
               @"generator": @"search",
               // search
               @"gsrsearch": [NSString stringWithFormat:@"morelike:%@", params.title.text],
               @"gsrnamespace": @0,
               @"gsrwhat": @"text",
               @"gsrinfo": @"",
               @"gsrprop": @"redirecttitle",
               @"gsroffset": @0,
               @"gsrlimit": numResults,
               // extracts
               @"exintro": @YES,
               @"exlimit": numResults,
               @"exchars": @(params.numberOfExtractCharacters),
               // pageterms
               @"wbptterms": @"description",
               // pageimage
               @"piprop": @"thumbnail",
               @"pithumbsize": @(LEAD_IMAGE_WIDTH),
               @"pilimit": numResults,
    };
}

@end

NS_ASSUME_NONNULL_END
