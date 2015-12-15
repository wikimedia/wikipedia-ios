
#import "SavedArticlesFetcher_Testing.h"

#import "Wikipedia-Swift.h"
#import "WMFArticleFetcher.h"
#import "MWKImageInfoFetcher.h"

#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKArticle.h"
#import "MWKImage+CanonicalFilenames.h"

static DDLogLevel const WMFSavedArticlesFetcherLogLevel = DDLogLevelDebug;

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFSavedArticlesFetcherLogLevel

NS_ASSUME_NONNULL_BEGIN

@interface SavedArticlesFetcher ()

@property (nonatomic, strong) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) WMFArticleFetcher* articleFetcher;
@property (nonatomic, strong) WMFImageController* imageController;
@property (nonatomic, strong) MWKImageInfoFetcher* imageInfoFetcher;

@property (nonatomic, strong) NSMutableDictionary<MWKTitle*, AnyPromise*>* fetchOperationsByArticleTitle;
@property (nonatomic, strong) NSMutableDictionary<MWKTitle*, NSError*>* errorsByArticleTitle;

@end

@implementation SavedArticlesFetcher

@dynamic fetchFinishedDelegate;

#pragma mark - Shared Access

static SavedArticlesFetcher* _articleFetcher = nil;

- (instancetype)initWithSavedPageList:(MWKSavedPageList*)savedPageList
                       articleFetcher:(WMFArticleFetcher*)articleFetcher
                      imageController:(WMFImageController*)imageController
                     imageInfoFetcher:(MWKImageInfoFetcher*)imageInfoFetcher {
    NSParameterAssert(savedPageList);
    NSParameterAssert(savedPageList.dataStore);
    NSParameterAssert(articleFetcher);
    NSParameterAssert(imageController);
    NSParameterAssert(imageInfoFetcher);
    self = [super init];
    if (self) {
        _accessQueue                       = dispatch_queue_create("org.wikipedia.savedarticlesarticleFetcher.accessQueue", DISPATCH_QUEUE_SERIAL);
        self.fetchOperationsByArticleTitle = [NSMutableDictionary new];
        self.errorsByArticleTitle          = [NSMutableDictionary new];
        self.articleFetcher                = articleFetcher;
        self.imageController               = imageController;
        self.savedPageList                 = savedPageList;
        self.imageInfoFetcher              = imageInfoFetcher;
    }
    return self;
}

- (instancetype)initWithSavedPageList:(MWKSavedPageList*)savedPageList {
    return [self initWithSavedPageList:savedPageList
                        articleFetcher:[[WMFArticleFetcher alloc] initWithDataStore:savedPageList.dataStore]
                       imageController:[WMFImageController sharedInstance]
                      imageInfoFetcher:[[MWKImageInfoFetcher alloc] init]];
}

#pragma mark - Fetching

- (void)fetchAndObserveSavedPageList {
    // build up initial state of current list
    [self fetchUncachedEntries:self.savedPageList.entries];

    // observe subsequent changes
    [self.KVOControllerNonRetaining observe:self.savedPageList
                                    keyPath:WMF_SAFE_KEYPATH(self.savedPageList, entries)
                                    options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                                     action:@selector(savedPageListDidChange:)];
}

- (void)cancelFetch {
    [self cancelFetchForEntries:self.savedPageList.entries];
}

#pragma mark Internal Methods

- (void)fetchUncachedEntries:(NSArray<MWKSavedPageEntry*>*)insertedEntries {
    if (!insertedEntries.count) {
        return;
    }
    [self fetchUncachedTitles:[insertedEntries valueForKey:WMF_SAFE_KEYPATH([MWKSavedPageEntry new], title)]];
}

- (void)cancelFetchForEntries:(NSArray<MWKSavedPageEntry*>*)deletedEntries {
    if (!deletedEntries.count) {
        return;
    }
    @weakify(self);
    dispatch_async(self.accessQueue, ^{
        @strongify(self);
        BOOL wasFetching = self.fetchOperationsByArticleTitle.count > 0;
        [deletedEntries bk_each:^(MWKSavedPageEntry* entry) {
            [self cancelFetchForTitle:entry.title];
        }];
        if (wasFetching) {
            /*
               only notify delegate if deletion occurs during a download session. if deletion occurs
               after the fact, we don't need to inform delegate of completion
             */
            [self notifyDelegateIfFinished];
        }
    });
}

- (void)fetchUncachedTitles:(NSArray<MWKTitle*>*)titles {
    if (!titles.count) {
        return;
    }
    dispatch_async(self.accessQueue, ^{
        for (MWKTitle* title in titles) {
            [self fetchTitle:title];
        }
    });
}

- (void)fetchTitle:(MWKTitle*)title {
    /*
       !!!: Use `articleFromDiskWithTitle:` to bypass object cache, preventing multi-threaded manipulation of
       objects in cache. This method should also be safe to call from any thread because it reads directly from disk.
     */
    MWKArticle* cachedArticle = [self.savedPageList.dataStore articleFromDiskWithTitle:title];
    if (cachedArticle) {
        [self downloadImageDataForArticle:cachedArticle];
        return;
    }

    /*
       don't use "finallyOn" to remove the promise from our tracking dictionary since it has to be removed
       immediately in order to ensure accurate progress & error reporting.
     */
    @weakify(self);
    self.fetchOperationsByArticleTitle[title] = [self.articleFetcher fetchArticleForPageTitle:title progress:NULL]
                                                .thenOn(self.accessQueue, ^(MWKArticle* article){
        @strongify(self);
        [self downloadImageDataForArticle:article];
        // HAX: fetch callbacks happen after image downloads start so we can verify them in tests
        // this is caused by the fact that we success notifications nor progress include article image or gallery downloads
        [self didFetchArticle:article title:title error:nil];
    }).catch(^(NSError* error){
        if (!self) {
            return;
        }
        dispatch_async(self.accessQueue, ^{
            [self didFetchArticle:nil title:title error:error];
        });
    });
}

- (void)downloadImageDataForArticle:(MWKArticle*)article {
    // NOTE: this is idempotent, so re-fetching has very low overhead (just checking they're all on disk)
    [self fetchAllImagesInArticle:article];
    // gallery data wasn't previously downloaded for saved pages, so must ensure this for backwards compat
    [self fetchGalleryInfoAndImagesForArticle:article];
}

- (void)fetchAllImagesInArticle:(MWKArticle*)article {
    [[article allImageURLs] bk_each:^(NSURL* imageURL) {
        // fetch all article images, but don't block success on their completion or consider failed image
        // download an error
        [self.imageController fetchImageWithURLInBackground:imageURL];
    }];
}

- (void)fetchGalleryInfoAndImagesForArticle:(MWKArticle*)article {
    @weakify(self);
    [self fetchImageInfoForImagesInArticle:article].then(^(NSArray<MWKImageInfo*>* info) {
        @strongify(self);
        if (!self) {
            return;
        }
        PMKWhen([info bk_map:^(MWKImageInfo* info) {
            return [self.imageController fetchImageWithURLInBackground:info.imageThumbURL];
        }])
        .then(^(NSArray* downloadResults) {
            DDLogVerbose(@"Downloaded results for images in gallery for %@: %@", article.title, downloadResults);
        });
    });
}

- (AnyPromise*)fetchImageInfoForImagesInArticle:(MWKArticle*)article {
    @weakify(self);
    return PMKWhen([[[MWKImage mapFilenamesFromImages:article.images.uniqueLargestVariants] bk_reject:^BOOL(id obj) {
        return [obj isEqual:[NSNull null]];
    }] bk_map:^AnyPromise*(NSString* canonicalFilename) {
        return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
            [self.imageInfoFetcher fetchGalleryInfoForImageFiles:@[canonicalFilename]
                                                        fromSite:article.title.site
                                                         success:^(NSArray* infoObjects) {
                resolve(infoObjects.firstObject);
            }
                                                         failure:resolve];
        }];
    }])
           .thenInBackground(^id (NSArray* infoOrError) {
        DDLogVerbose(@"Download results for imageinfo info for %@: %@", article.title, infoOrError);
        NSArray<MWKImageInfo*>* infoObjects = [infoOrError bk_reject:^BOOL (id obj) {
            return [obj isKindOfClass:[NSError class]] || [obj isEqual:[NSNull null]];
        }];

        @strongify(self);

        if (!self || infoObjects.count == 0) {
            return [NSError cancelledError];
        }

        [self.savedPageList.dataStore saveImageInfo:infoObjects forTitle:article.title];

        return infoObjects;
    });
}

#pragma mark - Cancellation

- (void)cancelFetchForTitle:(MWKTitle*)title {
    DDLogVerbose(@"Canceling saved page download for title: %@", title);
    [self.articleFetcher cancelFetchForPageTitle:title];
    [[[self.savedPageList.dataStore existingArticleWithTitle:title] allImageURLs] bk_each:^(NSURL* imageURL) {
        [self.imageController cancelFetchForURL:imageURL];
    }];
    WMF_TECH_DEBT_TODO(cancel image info & high-res image requests)
    [self.fetchOperationsByArticleTitle removeObjectForKey:title];
}

#pragma mark - KVO

- (void)savedPageListDidChange:(NSDictionary*)change {
    switch ([change[NSKeyValueChangeKindKey] integerValue]) {
        case NSKeyValueChangeInsertion: {
            [self fetchUncachedEntries:change[NSKeyValueChangeNewKey]];
            break;
        }
        case NSKeyValueChangeRemoval: {
            [self cancelFetchForEntries:change[NSKeyValueChangeOldKey]];
            break;
        }
        default:
            NSAssert(NO, @"Unsupported KVO operation %@ on saved page list %@", change, self.savedPageList);
            break;
    }
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
- (void)didFetchArticle:(MWKArticle* __nullable)fetchedArticle
                  title:(MWKTitle*)title
                  error:(NSError* __nullable)error {
    if (error) {
        // store errors for later reporting
        DDLogError(@"Failed to download saved page %@ due to error: %@", title, error);
        self.errorsByArticleTitle[title] = error;
    } else {
        DDLogInfo(@"Downloaded saved page: %@", title);
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

        DDLogInfo(@"Finished downloading all saved pages!");

        [self finishWithError:reportedError
                  fetchedData:nil];
    }
}

@end

NS_ASSUME_NONNULL_END
