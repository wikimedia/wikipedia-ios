
#import "WMFArticleFetcher.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "ArticleFetcher.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleFetcher ()

@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;
@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;
@property (nonatomic, strong) ArticleFetcher* fetcher;

@end

@implementation WMFArticleFetcher

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        self.operationManager      = manager;
    }
    return self;
}

- (ArticleFetcher*)fetcher {
    if (!_fetcher) {
        _fetcher = [[ArticleFetcher alloc] init];
    }

    return _fetcher;
}

- (AnyPromise*)fetchArticleForPageTitle:(MWKTitle*)pageTitle progress:(WMFProgressHandler __nullable)progress {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        AFHTTPRequestOperation* operation =
            [self.fetcher fetchSectionsForTitle:pageTitle
                                    inDataStore:self.dataStore
                                    withManager:self.operationManager
                                  progressBlock:progress
                                completionBlock:resolve
                                     errorBlock:resolve];
        if (!operation) {
            resolve([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
        }
    }];
}

@end

NS_ASSUME_NONNULL_END