
#import "WMFRandomArticleFetcher.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "WMFApiJsonResponseSerializer.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFNumberOfExtractCharacters.h"


#import "MWKSite.h"
#import "MWKSearchResult.h"

//Promises
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomArticleFetcher ()

@property (nonatomic, strong) MWKSite* site;
@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@end

@implementation WMFRandomArticleFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.responseSerializer = [WMFApiJsonResponseSerializer serializer];
        manager.responseSerializer = [WMFMantleJSONResponseSerializer serializerForValuesInDictionaryOfType:[MWKSearchResult class]
                                                                                                fromKeypath:@"query.pages"];
        self.operationManager = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (AnyPromise*)fetchRandomArticleWithSite:(MWKSite*)site {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self fetchRandomArticleWithSite:site useDesktopURL:NO resolver:resolve];
    }];
}

- (void)fetchRandomArticleWithSite:(MWKSite*)site
                     useDesktopURL:(BOOL)useDeskTopURL
                          resolver:(PMKResolver)resolve {
    NSURL* url           = [site apiEndpoint:useDeskTopURL];
    NSDictionary* params = [[self class] params];

    [self.operationManager GET:url.absoluteString
                    parameters:params
                       success:^(AFHTTPRequestOperation* operation, id response) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        MWKSearchResult* article = [response firstObject];
        resolve(article);
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        if ([url isEqual:[site mobileApiEndpoint]] && [error wmf_shouldFallbackToDesktopURLError]) {
            [self fetchRandomArticleWithSite:site useDesktopURL:YES resolver:resolve];
        } else {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }
    }];
}

+ (NSDictionary*)params {
    return @{
               @"action": @"query",
               @"prop": @"extracts|pageterms|pageimages",
               //random
               @"generator": @"random",
               @"grnnamespace": @0,
               @"grnfilterredir": @"nonredirects",
               @"grnlimit": @"1",
               // extracts
               @"exintro": @YES,
               @"exlimit": @"1",
               @"explaintext": @"",
               @"exchars": @(WMFNumberOfExtractCharacters),
               // pageterms
               @"wbptterms": @"description",
               // pageimage
               @"piprop": @"thumbnail",
               @"pithumbsize": @(LEAD_IMAGE_WIDTH),
               @"pilimit": @"1",
               @"format": @"json",
    };
}

@end


NS_ASSUME_NONNULL_END