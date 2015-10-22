
#import "WMFRandomArticleFetcher.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "WMFApiJsonResponseSerializer.h"
#import "MWKSite.h"

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
        self.operationManager      = manager;
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
    NSDictionary* params = @{
        @"action": @"query",
        @"list": @"random",
        @"rnlimit": @"1",
        @"rnnamespace": @"0",
        @"format": @"json"
    };

    [self.operationManager GET:url.absoluteString
                    parameters:params
                       success:^(AFHTTPRequestOperation* operation, id response) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        NSArray* randomArticles = (NSArray*)response[@"query"][@"random"];
        NSDictionary* article = [randomArticles objectAtIndex:0];
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

@end


NS_ASSUME_NONNULL_END