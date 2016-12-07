#import "WMFRandomArticleFetcher.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "AFHTTPSessionManager+WMFDesktopRetry.h"
#import "WMFApiJsonResponseSerializer.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFNumberOfExtractCharacters.h"

#import "MWKSearchResult.h"

#import <BlocksKit/BlocksKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomArticleFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager *operationManager;

@end

@implementation WMFRandomArticleFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.responseSerializer = [WMFMantleJSONResponseSerializer serializerForValuesInDictionaryOfType:[MWKSearchResult class]
                                                                                                fromKeypath:@"query.pages"];
        self.operationManager = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (void)fetchRandomArticleWithSiteURL:(NSURL *)siteURL failure:(nonnull WMFErrorHandler)failure success:(nonnull WMFMWKSearchResultHandler)success {
    NSDictionary *params = [[self class] params];

    [self.operationManager wmf_GETAndRetryWithURL:siteURL
        parameters:params
        retry:NULL
        success:^(NSURLSessionDataTask *operation, NSArray *responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            MWKSearchResult *article = [self getBestRandomResultFromResults:responseObject];

            success(article);
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            failure(error);
        }];
}

- (MWKSearchResult *)getBestRandomResultFromResults:(NSArray *)results {
    //Sort so random results with good extracts and images come first and disambiguation pages come last.
    NSSortDescriptor *extractSorter = [[NSSortDescriptor alloc] initWithKey:@"extract.length" ascending:NO];
    NSSortDescriptor *descripSorter = [[NSSortDescriptor alloc] initWithKey:@"wikidataDescription" ascending:NO];
    NSSortDescriptor *thumbSorter = [[NSSortDescriptor alloc] initWithKey:@"thumbnailURL.absoluteString" ascending:NO];
    NSSortDescriptor *disambigSorter = [[NSSortDescriptor alloc] initWithKey:@"isDisambiguation" ascending:YES];
    NSSortDescriptor *listSorter = [[NSSortDescriptor alloc] initWithKey:@"isList" ascending:YES];
    results = [results sortedArrayUsingDescriptors:@[disambigSorter, listSorter, thumbSorter, descripSorter, extractSorter]];
    return [results firstObject];
}

+ (NSDictionary *)params {
    NSNumber *numberOfRandomItemsToFetch = @8;
    return @{
        @"action": @"query",
        @"prop": @"extracts|pageterms|pageimages|pageprops|revisions",
        //random
        @"generator": @"random",
        @"grnnamespace": @0,
        @"grnfilterredir": @"nonredirects",
        @"grnlimit": numberOfRandomItemsToFetch,
        // extracts
        @"exintro": @YES,
        @"exlimit": numberOfRandomItemsToFetch,
        @"explaintext": @"",
        @"exchars": @(WMFNumberOfExtractCharacters),
        // pageterms
        @"wbptterms": @"description",
        // pageimage
        @"piprop": @"thumbnail",
        @"pithumbsize": [[UIScreen mainScreen] wmf_leadImageWidthForScale],
        @"pilimit": numberOfRandomItemsToFetch,
        // revision
        @"rrvlimit": @(1),
        @"rvprop": @"ids",
        @"format": @"json",
    };
}

@end

NS_ASSUME_NONNULL_END
