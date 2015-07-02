
#import "WMFArticleFetcher.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "ArticleFetcher.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

NS_ASSUME_NONNULL_BEGIN

NSString* const WMFArticleFetchedNotification = @"WMFArticleFetchedNotification";
NSString* const WMFArticleFetchedKey          = @"WMFArticleFetchedKey";

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

- (AnyPromise*)fetchArticleForPageTitle:(MWKTitle*)pageTitle progress:(WMFProgressHandler)progress {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        AFHTTPRequestOperation* operation = [self.fetcher fetchSectionsForTitle:pageTitle inDataStore:self.dataStore withManager:self.operationManager progressBlock:^(CGFloat completionProgress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (progress) {
                    progress(completionProgress);
                }
            });
        } completionBlock:^(MWKArticle* article) {
            [[NSNotificationCenter defaultCenter] postNotificationName:WMFArticleFetchedNotification object:self userInfo:@{WMFArticleFetchedKey: article}];
            resolve(article);
        } errorBlock:^(NSError* error) {
            resolve(error);
        }];

        if (operation == nil) {
            resolve([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
        }
    }];
}

@end

NS_ASSUME_NONNULL_END