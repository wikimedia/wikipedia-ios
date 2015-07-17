
#import "SavedArticlesFetcher.h"
#import "ArticleFetcher.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "MediaWikiKit.h"

@interface SavedArticlesFetcher ()

@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPageList;
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;
@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@property (nonatomic, strong) NSMutableDictionary* fetchersByArticleTitle;
@property (nonatomic, strong) NSMutableDictionary* errorsByArticleTitle;

@property (nonatomic, strong) NSMutableArray* fetchedArticles;

@property (nonatomic, strong) dispatch_queue_t accessQueue;

@end

@implementation SavedArticlesFetcher

@dynamic fetchFinishedDelegate;

#pragma mark - Shared Access

static SavedArticlesFetcher* _fetcher = nil;

+ (SavedArticlesFetcher*)sharedInstance {
    return _fetcher;
}

+ (void)setSharedInstance:(SavedArticlesFetcher*)fetcher {
    _fetcher = fetcher;
}

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(dataStore != nil);

    self = [super init];
    if (self) {
        self.dataStore   = dataStore;
        self.accessQueue = dispatch_queue_create("org.wikipedia.savedarticlesfetcher.accessQueue", DISPATCH_QUEUE_SERIAL);
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        self.operationManager      = manager;
    }
    return self;
}

- (void)fetchSavedPageList:(MWKSavedPageList*)savedPageList {
    self.savedPageList = savedPageList;
    [self cancelFetch];

    dispatch_async(self.accessQueue, ^{
        self.fetchersByArticleTitle = [NSMutableDictionary dictionary];
        self.errorsByArticleTitle = [NSMutableDictionary dictionary];
        self.fetchedArticles = [NSMutableArray array];

        for (MWKSavedPageEntry* entry in self.savedPageList) {
            if (entry.title) {
                ArticleFetcher* fetcher = [[ArticleFetcher alloc] init];
                self.fetchersByArticleTitle[entry.title] = fetcher;

                [fetcher fetchSectionsForTitle:entry.title inDataStore:self.dataStore fetchLeadSectionOnly:NO withManager:self.operationManager progressBlock:NULL completionBlock:^(MWKArticle* article) {
                    MWKArticle* fetchedArticle = article;

                    dispatch_async(self.accessQueue, ^{
                        [self.fetchersByArticleTitle removeObjectForKey:entry.title];
                        [self.fetchedArticles addObject:fetchedArticle];
                        [self notifyDelegateProgressWithFetchedArticle:fetchedArticle error:nil];
                        [self notifyDelegateCompletionIfFinished];
                    });
                } errorBlock:^(NSError* error) {
                    [self.fetchersByArticleTitle removeObjectForKey:entry.title];
                    self.errorsByArticleTitle[entry.title] = error;
                    [self notifyDelegateProgressWithFetchedArticle:nil error:error];
                    [self notifyDelegateCompletionIfFinished];
                }];
            }
        }
    });
}

- (void)cancelFetch {
    [self.operationManager.operationQueue cancelAllOperations];
}

#pragma mark - Progress

- (void)getProgress:(WMFProgressHandler)progressBlock {
    dispatch_async(self.accessQueue, ^{
        CGFloat progress = [self progress];

        dispatch_async(dispatch_get_main_queue(), ^{
            progressBlock(progress);
        });
    });
}

- (CGFloat)progress {
    if ([self.savedPageList countOfEntries] == 0) {
        return 0.0;
    }

    return (CGFloat)([self.savedPageList countOfEntries] - [self.fetchersByArticleTitle count]) / (CGFloat)[self.savedPageList countOfEntries];
}

#pragma mark - Delegate Notification

- (void)notifyDelegateProgressWithFetchedArticle:(MWKArticle*)fetchedArticle error:(NSError*)error {
    dispatch_async(self.accessQueue, ^{
        CGFloat progress = [self progress];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.fetchFinishedDelegate savedArticlesFetcher:self didFetchArticle:fetchedArticle progress:progress error:error];
        });
    });
}

- (void)notifyDelegateCompletionIfFinished {
    dispatch_async(self.accessQueue, ^{
        if ([self.fetchersByArticleTitle count] == 0) {
            NSError* reportedError;
            if ([self.errorsByArticleTitle count] > 0) {
                reportedError = [[self.errorsByArticleTitle allValues] firstObject];
            }

            [self finishWithError:reportedError
                      fetchedData:self.fetchedArticles];

            [[self class] setSharedInstance:nil];
        }
    });
}

@end
