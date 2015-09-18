
#import "SavedArticlesFetcher.h"

#import "Wikipedia-Swift.h"
#import "WMFArticleFetcher.h"

#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKArticle.h"

@interface SavedArticlesFetcher ()

@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) WMFArticleFetcher* fetcher;

@property (nonatomic, strong) NSMutableDictionary<MWKTitle*, AnyPromise*>* fetchOperationsByArticleTitle;
@property (nonatomic, strong) NSMutableDictionary<MWKTitle*, NSError*>* errorsByArticleTitle;

@property (nonatomic, strong) dispatch_queue_t accessQueue;

@end

@implementation SavedArticlesFetcher

@dynamic fetchFinishedDelegate;

#pragma mark - Shared Access

static SavedArticlesFetcher* _fetcher = nil;

+ (SavedArticlesFetcher*)sharedInstance {
    NSParameterAssert([NSThread isMainThread]);
    return _fetcher;
}

+ (void)setSharedInstance:(SavedArticlesFetcher*)fetcher {
    NSParameterAssert([NSThread isMainThread]);
    _fetcher = fetcher;
}

- (instancetype)initWithArticleFetcher:(WMFArticleFetcher*)articleFetcher {
    NSParameterAssert(articleFetcher);
    self = [super init];
    if (self) {
        self.accessQueue   = dispatch_queue_create("org.wikipedia.savedarticlesfetcher.accessQueue",
                                                   DISPATCH_QUEUE_SERIAL);
        self.fetcher = articleFetcher;
    }
    return self;
}

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    return [self initWithArticleFetcher:[[WMFArticleFetcher alloc] initWithDataStore:dataStore]];
}

#pragma mark - Fetching

- (void)fetchSavedPageList:(MWKSavedPageList*)savedPageList {
    // Using identity instead of equivalence since updates to an instance are more important than equivalent state
    if (self.savedPageList == savedPageList) {
        return;
    }

    [self.KVOControllerNonRetaining unobserve:self.savedPageList];
    [self cancelFetch];

    self.savedPageList = savedPageList;

    if (!self.savedPageList) {
        return;
    }

    // build up initial state of current list
    [self startFetching];

    // observe subsequent changes
    [self.KVOControllerNonRetaining observe:self.savedPageList
                                    keyPath:WMF_SAFE_KEYPATH(self.savedPageList, entries)
                                    options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                                     action:@selector(savedPageListDidChange:)];
}

- (void)startFetching {
    [self fetchTitles:[self.savedPageList.entries valueForKey:WMF_SAFE_KEYPATH([MWKSavedPageEntry new], title)]];
}

- (void)fetchTitles:(NSArray<MWKTitle*>*)titles {
    if (!titles.count) {
        return;
    }
    dispatch_async(self.accessQueue, ^{
        for (MWKTitle* title in titles) {
            self.fetchOperationsByArticleTitle[title] = [self.fetcher fetchArticleForPageTitle:title
                                                                                      progress:NULL]
                                                        .thenOn(self.accessQueue, ^(MWKArticle* article){
                [self didFinishDownloadingArticle:article];
            })
                                                        .catch(^(NSError* error){
                [self failedToDownloadArticleWithTitle:title error:error];
            })
                                                        .finallyOn(self.accessQueue, ^{
                [self.fetchOperationsByArticleTitle removeObjectForKey:title];
            });
        }
    });
}

/// Only invoke within accessQueue
- (void)didFinishDownloadingArticle:(MWKArticle*)article {
    [self notifyDelegateProgressWithFetchedArticle:article error:nil];
    [self notifyDelegateCompletionIfFinished];
}

- (void)failedToDownloadArticleWithTitle:(MWKTitle*)title error:(NSError*)error {
    dispatch_async(self.accessQueue, ^{
        self.errorsByArticleTitle[title] = error;
        [self notifyDelegateProgressWithFetchedArticle:nil error:error];
        [self notifyDelegateCompletionIfFinished];
    });
}

- (void)cancelFetch {
    [self.fetcher cancelAllFetches];
}

#pragma mark - KVO

- (void)savedPageListDidChange:(NSDictionary*)change {
    switch ([change[NSKeyValueChangeKindKey] integerValue]) {
        case NSKeyValueChangeInsertion: {
            [self savedPageListDidAddItemsAtIndexes:change[NSKeyValueChangeIndexesKey]];
            break;
         }
        case NSKeyValueChangeRemoval: {
            [self savedPageListDidDeleteItemsAtIndexes:change[NSKeyValueChangeIndexesKey]];
            break;
        }
        case NSKeyValueChangeSetting: {
            [self mergeFetchesWithUpdatedSavedPageList];
            break;
        }
        default:
            break;
    }
}

- (void)savedPageListDidDeleteItemsAtIndexes:(NSIndexSet*)deletedIndexes {
    if (!deletedIndexes.count) {
        return;
    }
    [[self.savedPageList.entries objectsAtIndexes:deletedIndexes] bk_each:^(MWKTitle* title) {
        [self.fetcher cancelFetchForPageTitle:title];
    }];
}

- (void)savedPageListDidAddItemsAtIndexes:(NSIndexSet*)insertedIndexes {
    if (!insertedIndexes.count) {
        return;
    }
    [self fetchTitles:[self.savedPageList.entries objectsAtIndexes:insertedIndexes]];
}

- (void)mergeFetchesWithUpdatedSavedPageList {
    // using an array for quick containment checks
    NSArray<MWKTitle*>* currentSavedTitles =
        [self.savedPageList.entries valueForKey:WMF_SAFE_KEYPATH([MWKSavedPageEntry new], title)];
    dispatch_async(self.accessQueue, ^{
        NSArray<MWKTitle*>* cancelledFetchTitles =
        [self.fetchOperationsByArticleTitle.allKeys bk_reject:^BOOL(MWKTitle* title) {
            return ![currentSavedTitles containsObject:title];
        }];
        [cancelledFetchTitles bk_each:^(MWKTitle* title) {
            [self.fetcher cancelFetchForPageTitle:title];
        }];
        [self.fetchOperationsByArticleTitle removeObjectsForKeys:cancelledFetchTitles];
        NSArray<MWKTitle*>* titlesToFetch = [currentSavedTitles bk_reject:^BOOL(MWKTitle* title) {
            return [self.fetchOperationsByArticleTitle.allKeys containsObject:title];
        }];
        [self fetchTitles:titlesToFetch];
    });
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

/// Only invoke within accessQueue
- (CGFloat)progress {
    if ([self.savedPageList countOfEntries] == 0) {
        return 0.0;
    }

    return (CGFloat)([self.savedPageList countOfEntries] - [self.fetchOperationsByArticleTitle count])
            / (CGFloat)[self.savedPageList countOfEntries];
}

#pragma mark - Delegate Notification

/// Only invoke within accessQueue
- (void)notifyDelegateProgressWithFetchedArticle:(MWKArticle*)fetchedArticle
                                           error:(NSError*)error {
    CGFloat progress = [self progress];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.fetchFinishedDelegate savedArticlesFetcher:self
                                         didFetchArticle:fetchedArticle
                                                progress:progress
                                                   error:error];
    });
}

/// Only invoke within accessQueue
- (void)notifyDelegateCompletionIfFinished {
    if ([self.fetchOperationsByArticleTitle count] == 0) {
        NSError* reportedError;
        if ([self.errorsByArticleTitle count] > 0) {
            reportedError = [[self.errorsByArticleTitle allValues] firstObject];
        }

        [self finishWithError:reportedError
                  fetchedData:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[self class] setSharedInstance:nil];
        });
    }
}

@end
