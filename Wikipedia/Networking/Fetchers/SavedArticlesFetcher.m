
#import "SavedArticlesFetcher.h"
#import "WMFArticleFetcher.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

@interface SavedArticlesFetcher ()

@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPageList;
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;
@property (nonatomic, strong) WMFArticleFetcher* fetcher;

@property (nonatomic, strong) NSMutableDictionary* fetchOperationsByArticleTitle;
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
        self.fetcher     = [[WMFArticleFetcher alloc] initWithDataStore:self.dataStore];
    }
    return self;
}

- (void)fetchSavedPageList:(MWKSavedPageList*)savedPageList {
    self.savedPageList = savedPageList;
    [self cancelFetch];

    dispatch_async(self.accessQueue, ^{
        self.fetchOperationsByArticleTitle = [NSMutableDictionary dictionary];
        self.fetchedArticles = [NSMutableArray array];
        self.errorsByArticleTitle = [NSMutableDictionary dictionary];

        for (MWKSavedPageEntry* entry in self.savedPageList) {
            if (entry.title) {
                self.fetchOperationsByArticleTitle[entry.title] = [self.fetcher fetchArticleForPageTitle:entry.title progress:NULL].thenOn(self.accessQueue, ^(MWKArticle* article){
                    [self.fetchOperationsByArticleTitle removeObjectForKey:entry.title];
                    [self.fetchedArticles addObject:article];
                    [self notifyDelegateProgressWithFetchedArticle:article error:nil];
                    [self notifyDelegateCompletionIfFinished];
                }).catch(^(NSError* error){
                    dispatch_async(self.accessQueue, ^{
                        [self.fetchOperationsByArticleTitle removeObjectForKey:entry.title];
                        self.errorsByArticleTitle[entry.title] = error;
                        [self notifyDelegateProgressWithFetchedArticle:nil error:error];
                        [self notifyDelegateCompletionIfFinished];
                    });
                });
            }
        }
    });
}

- (void)cancelFetch {
    [self.fetcher cancelAllFetches];
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

    return (CGFloat)([self.savedPageList countOfEntries] - [self.fetchOperationsByArticleTitle count]) / (CGFloat)[self.savedPageList countOfEntries];
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
        if ([self.fetchOperationsByArticleTitle count] == 0) {
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
