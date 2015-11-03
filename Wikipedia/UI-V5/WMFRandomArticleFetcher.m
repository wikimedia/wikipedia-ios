
#import "WMFRandomArticleFetcher.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
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
        NSDictionary* params = [[self class] params];

        [self.operationManager wmf_GETWithSite:site
                                    parameters:params
                                         retry:NULL
                                       success:^(AFHTTPRequestOperation* operation, id responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            MWKSearchResult* article = [responseObject firstObject];
            resolve(article);
        } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }];
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