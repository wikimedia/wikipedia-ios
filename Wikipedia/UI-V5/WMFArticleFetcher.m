
#import "WMFArticleFetcher.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "ArticleFetcher.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleFetcher ()<ArticleFetcherDelegate>

@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;

@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@property (nonatomic, strong) ArticleFetcher* fetcher;

@property (nonatomic, strong, nullable) AFHTTPRequestOperation* operation;
@property (nonatomic, copy, nullable) WMFArticleFetcherProgress progressBlock;
@property (nonatomic, copy, nullable) PMKResolver resolver;

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

- (AnyPromise*)fetchArticleForPageTitle:(MWKTitle*)pageTitle progress:(WMFArticleFetcherProgress)progress {
    [self cancelCurrentFetch];

    self.progressBlock = progress;

    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        self.resolver = resolve;

        self.fetcher = [[ArticleFetcher alloc] init];
        self.operation = [self.fetcher fetchSectionsForTitle:pageTitle inDataStore:self.dataStore withManager:self.operationManager thenNotifyDelegate:self];

        if (self.operation == nil) {
            resolve([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
            [self reset];
        }
    }];
}

- (void)articleFetcher:(ArticleFetcher*)savedArticlesFetcher
     didUpdateProgress:(CGFloat)progress {
    if (!self.progressBlock) {
        return;
    }

    dispatchOnMainQueue(^{
        self.progressBlock(progress);
    });
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error {
    if (!self.resolver) {
        [self reset];
        return;
    }

    MWKArticle* article = fetchedData;

    if (!error) {
        MWKTitle* redirectedTitle = article.redirected;
        if (redirectedTitle) {
            error = [NSError wmf_redirectedErrorWithTitle:redirectedTitle];
        }
    }

    if (!error) {
        self.resolver(article);
    } else {
        self.resolver(error);
    }
    [self reset];
}

- (void)cancelCurrentFetch {
    [self.operation cancel];
    [self reset];
}

- (void)reset {
    self.operation     = nil;
    self.progressBlock = NULL;
    self.resolver      = nil;
}

@end

NS_ASSUME_NONNULL_END