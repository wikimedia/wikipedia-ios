
#import "SavedArticlesFetcher_Testing.h"

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
        _accessQueue   = dispatch_queue_create("org.wikipedia.savedarticlesfetcher.accessQueue", DISPATCH_QUEUE_SERIAL);
        self.fetchOperationsByArticleTitle = [NSMutableDictionary new];
        self.errorsByArticleTitle = [NSMutableDictionary new];
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
            /*
             !!!: Use `articleFromDiskWithTitle:` to bypass object cache, preventing multi-threaded manipulation of 
             objects in cache
            */
            MWKArticle* existingArticle = [self.savedPageList.dataStore articleFromDiskWithTitle:title];
            if (existingArticle.isCached) {
                continue;
            }

            /*
             NOTE: don't use "finallyOn" to remove the promise from our tracking dictionary since it has to be removed
             immediately in order for accurate progress & error reporting
            */
            self.fetchOperationsByArticleTitle[title] = [self.fetcher fetchArticleForPageTitle:title
                                                                                      progress:NULL]
                                                        .thenOn(self.accessQueue, ^(MWKArticle* article){
                [self didFetchArticle:article title:title error:nil];
            })
                                                        .catch(^(NSError* error){
                dispatch_async(self.accessQueue, ^{
                    [self didFetchArticle:nil title:title error:error];
                });
            });
        }
    });
}

- (void)cancelFetch {
    [self.fetcher cancelAllFetches];
}

#pragma mark - KVO

- (void)savedPageListDidChange:(NSDictionary*)change {
    switch ([change[NSKeyValueChangeKindKey] integerValue]) {
        case NSKeyValueChangeInsertion: {
            [self savedPageListDidAddItems:change[NSKeyValueChangeNewKey]];
            break;
         }
        case NSKeyValueChangeRemoval: {
            [self savedPageListDidDeleteItems:change[NSKeyValueChangeOldKey]];
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

- (void)savedPageListDidDeleteItems:(NSArray<MWKSavedPageEntry*>*)deletedEntries {
    if (!deletedEntries.count) {
        return;
    }
    dispatch_async(self.accessQueue, ^{
        [deletedEntries bk_each:^(MWKSavedPageEntry* entry) {
            [self.fetcher cancelFetchForPageTitle:entry.title];
            [self.fetchOperationsByArticleTitle removeObjectForKey:entry.title];
        }];
        [self notifyDelegateIfFinished];
    });
}

- (void)savedPageListDidAddItems:(NSArray<MWKSavedPageEntry*>*)insertedEntries {
    if (!insertedEntries.count) {
        return;
    }
    [self fetchTitles:[insertedEntries valueForKey:WMF_SAFE_KEYPATH([MWKSavedPageEntry new], title)]];
}

- (void)mergeFetchesWithUpdatedSavedPageList {
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
    /*
     FIXME: Handle progress when only downloading a subset of saved pages (e.g. if some were already downloaded in
     a previous session)?
    */
    if ([self.savedPageList countOfEntries] == 0) {
        return 0.0;
    }

    return (CGFloat)([self.savedPageList countOfEntries] - [self.fetchOperationsByArticleTitle count])
            / (CGFloat)[self.savedPageList countOfEntries];
}

#pragma mark - Delegate Notification

/// Only invoke within accessQueue
- (void)didFetchArticle:(MWKArticle*)fetchedArticle
                  title:(MWKTitle*)title
                  error:(NSError*)error {
    if (error) {
        // store errors for later reporting
        self.errorsByArticleTitle[title] = error;
    }

    // stop tracking operation, effectively advancing the progress
    [self.fetchOperationsByArticleTitle removeObjectForKey:title];

    CGFloat progress = [self progress];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.fetchFinishedDelegate savedArticlesFetcher:self
                                           didFetchTitle:title
                                                 article:fetchedArticle
                                                progress:progress
                                                   error:error];
    });

    [self notifyDelegateIfFinished];
}

/// Only invoke within accessQueue
- (void)notifyDelegateIfFinished {
    if ([self.fetchOperationsByArticleTitle count] == 0) {
        NSError* reportedError;
        if ([self.errorsByArticleTitle count] > 0) {
            reportedError = [[self.errorsByArticleTitle allValues] firstObject];
        }

        [self.errorsByArticleTitle removeAllObjects];

        [self finishWithError:reportedError
                  fetchedData:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[self class] setSharedInstance:nil];
        });
    }
}

@end
