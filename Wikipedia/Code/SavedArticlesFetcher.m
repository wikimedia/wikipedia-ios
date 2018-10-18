@import WMF;
#import "Wikipedia-Swift.h"
#import "WMFArticleFetcher.h"
#import "MWKImageInfoFetcher.h"

NSString *const WMFArticleSaveToDiskDidFailNotification = @"WMFArticleSavedToDiskWithErrorNotification";
NSString *const WMFArticleSaveToDiskDidFailArticleURLKey = @"WMFArticleSavedToDiskWithArticleURLKey";
NSString *const WMFArticleSaveToDiskDidFailErrorKey = @"WMFArticleSavedToDiskWithErrorKey";

static DDLogLevel const WMFSavedArticlesFetcherLogLevel = DDLogLevelDebug;

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFSavedArticlesFetcherLogLevel

NS_ASSUME_NONNULL_BEGIN

@interface SavedArticlesFetcher ()

@property (nonatomic, strong, readwrite) dispatch_queue_t accessQueue;

@property (nonatomic, strong) MWKDataStore *dataStore;
@property (nonatomic, strong) WMFArticleFetcher *articleFetcher;
@property (nonatomic, strong) WMFImageController *imageController;
@property (nonatomic, strong) MWKImageInfoFetcher *imageInfoFetcher;
@property (nonatomic, strong) WMFSavedPageSpotlightManager *spotlightManager;

@property (nonatomic, getter=isUpdating) BOOL updating;
@property (nonatomic, getter=isRunning) BOOL running;

@property (nonatomic, strong) NSMutableDictionary<NSURL *, NSURLSessionTask *> *fetchOperationsByArticleTitle;
@property (nonatomic, strong) NSMutableDictionary<NSURL *, NSError *> *errorsByArticleTitle;

@property (nonatomic, strong) NSNumber *fetchesInProcessCount;

@property (nonatomic, strong) SavedArticlesFetcherProgressManager *savedArticlesFetcherProgressManager;

@end

@implementation SavedArticlesFetcher

#pragma mark - NSObject

static SavedArticlesFetcher *_articleFetcher = nil;

- (void)dealloc {
    [self stop];
}

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore
                   articleFetcher:(WMFArticleFetcher *)articleFetcher
                  imageController:(WMFImageController *)imageController
                 imageInfoFetcher:(MWKImageInfoFetcher *)imageInfoFetcher {
    NSParameterAssert(dataStore);
    NSParameterAssert(articleFetcher);
    NSParameterAssert(imageController);
    NSParameterAssert(imageInfoFetcher);
    self = [super init];
    if (self) {
        self.fetchesInProcessCount = @0;
        self.accessQueue = dispatch_queue_create("org.wikipedia.savedarticlesarticleFetcher.accessQueue", DISPATCH_QUEUE_SERIAL);
        self.fetchOperationsByArticleTitle = [NSMutableDictionary new];

        [self updateFetchesInProcessCount];

        self.errorsByArticleTitle = [NSMutableDictionary new];
        self.dataStore = dataStore;
        self.articleFetcher = articleFetcher;
        self.imageController = imageController;
        self.imageInfoFetcher = imageInfoFetcher;
        self.spotlightManager = [[WMFSavedPageSpotlightManager alloc] initWithDataStore:self.dataStore];
        self.savedArticlesFetcherProgressManager = [[SavedArticlesFetcherProgressManager alloc] initWithDelegate:self];
    }
    return self;
}

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    return [self initWithDataStore:dataStore
                    articleFetcher:[[WMFArticleFetcher alloc] initWithDataStore:dataStore]
                   imageController:[WMFImageController sharedInstance]
                  imageInfoFetcher:[[MWKImageInfoFetcher alloc] init]];
}

#pragma mark - Progress

// Reminder: due to the internal structure of this class and how it is presently being used, we can't simply check the 'count' of 'fetchOperationsByArticleTitle' dictionary for the total. (It doesn't reflect the actual total.) Could re-plumb this class later.
- (NSUInteger)calculateTotalArticlesToFetchCount {
    NSAssert([NSThread isMainThread], @"Must be called on the main thread");
    NSManagedObjectContext *moc = self.dataStore.viewContext;
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.includesSubentities = NO;
    request.predicate = [NSPredicate predicateWithFormat:@"savedDate != NULL && isDownloaded != YES"];
    NSError *fetchError = nil;
    NSUInteger count = [moc countForFetchRequest:request error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error counting number of article to be downloaded: %@", fetchError);
    }
    return count;
}

- (void)updateFetchesInProcessCount {
    NSUInteger count = [self calculateTotalArticlesToFetchCount];
    if (count == NSNotFound) {
        return;
    }
    self.fetchesInProcessCount = @(count);
}

#pragma mark - Public

- (void)start {
    self.running = YES;
    [self observeSavedPages];
    [self update];
}

- (void)stop {
    self.running = NO;
    [self unobserveSavedPages];
}

#pragma mark - Observing

- (void)articleWasUpdated:(NSNotification *)note {
    [self update];
}

- (void)_update {
    if (self.isUpdating || !self.isRunning) {
        [self updateFetchesInProcessCount];
        return;
    }
    self.updating = YES;
    NSAssert([NSThread isMainThread], @"Update must be called on the main thread");
    NSManagedObjectContext *moc = self.dataStore.viewContext;
    
    NSFetchRequest *request = [WMFArticle fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"savedDate != NULL && isDownloaded != YES"];
    request.fetchLimit = 1;
    NSError *fetchError = nil;
    WMFArticle *article = [[moc executeFetchRequest:request error:&fetchError] firstObject];
    if (fetchError) {
        DDLogError(@"Error fetching next article to download: %@", fetchError);
    }
    dispatch_block_t updateAgain = ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.updating = NO;
            [self update];
        });
    };
    if (article) {
        NSURL *articleURL = article.URL;
        if (articleURL) {
            [self fetchArticleURL:articleURL
                priority:NSURLSessionTaskPriorityLow
                failure:^(NSError *error) {
                    [self updateFetchesInProcessCount];
                    updateAgain();
                }
                success:^{
                    [self.spotlightManager addToIndexWithUrl:articleURL];
                    [self updateFetchesInProcessCount];
                    updateAgain();
                }];
        } else {
            self.updating = NO;
        }
    } else {
        NSFetchRequest *downloadedRequest = [WMFArticle fetchRequest];
        downloadedRequest.predicate = [NSPredicate predicateWithFormat:@"savedDate == nil && isDownloaded == YES"];
        downloadedRequest.fetchLimit = 1;
        NSError *downloadedFetchError = nil;
        WMFArticle *articleToDelete = [[self.dataStore.viewContext executeFetchRequest:downloadedRequest error:&downloadedFetchError] firstObject];
        if (downloadedFetchError) {
            DDLogError(@"Error fetching downloaded unsaved articles: %@", downloadedFetchError);
        }
        if (articleToDelete) {
            NSURL *articleURL = article.URL;
            if (!articleURL) {
                self.updating = NO;
                [self updateFetchesInProcessCount];
                return;
            }
            [self cancelFetchForArticleURL:articleURL];
            [self removeArticleWithURL:articleURL
                            completion:^{
                                updateAgain();
                                [self updateFetchesInProcessCount];
                            }];
            [self.spotlightManager removeFromIndexWithUrl:articleURL];
        } else {
            self.updating = NO;
            [self notifyDelegateIfFinished];
            [self updateFetchesInProcessCount];
        }
    }
}

- (void)update {
    NSAssert([NSThread isMainThread], @"Update must be called on the main thread");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_update) object:nil];
    [self performSelector:@selector(_update) withObject:nil afterDelay:0.5];
}

- (void)observeSavedPages {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleWasUpdated:) name:WMFArticleUpdatedNotification object:nil];
}

- (void)unobserveSavedPages {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Fetch

- (void)fetchArticleURL:(NSURL *)articleURL priority:(float)priority failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    WMFAssertMainThread(@"must be called on the main thread");
    if (!articleURL.wmf_title) {
        DDLogError(@"Attempted to save articleURL without title: %@", articleURL);
        failure([NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters userInfo:nil]);
        return;
    }

    if (self.fetchOperationsByArticleTitle[articleURL]) { // Protect against duplicate fetches & infinite fetch loops
        failure([NSError wmf_errorWithType:WMFErrorTypeFetchAlreadyInProgress userInfo:nil]);
        return;
    }

    // NOTE: must check isCached to determine that all article data has been downloaded
    MWKArticle *articleFromDisk = [self.dataStore articleWithURL:articleURL];
    if (articleFromDisk.isCached) {
        // only fetch images if article was cached
        [self downloadImageDataForArticle:articleFromDisk
            failure:^(NSError *_Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self didFetchArticle:articleFromDisk url:articleURL error:error];
                    failure(error);
                });
            }
            success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self didFetchArticle:articleFromDisk url:articleURL error:nil];
                    success();
                });
            }];
    } else {
        self.fetchOperationsByArticleTitle[articleURL] =
            [self.articleFetcher fetchArticleForURL:articleURL
                saveToDisk:YES
                priority:priority
                progress:NULL
                failure:^(NSError *_Nonnull error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self didFetchArticle:nil url:articleURL error:error];
                        failure(error);
                    });
                }
                success:^(MWKArticle *_Nonnull article) {
                    dispatch_async(self.accessQueue, ^{
                        [self downloadImageDataForArticle:article
                            failure:^(NSError *error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self didFetchArticle:article url:articleURL error:error];
                                    failure(error);
                                });
                            }
                            success:^{
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self didFetchArticle:article url:articleURL error:nil];
                                    success();
                                });
                            }];
                    });
                }];

        [self updateFetchesInProcessCount];
    }
}

- (void)downloadImageDataForArticle:(MWKArticle *)article failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    dispatch_block_t doneMigration = ^{
        [self fetchAllImagesInArticle:article
            failure:^(NSError *error) {
                failure([NSError wmf_savedPageImageDownloadError]);
            }
            success:^{
                if (success) {
                    success();
                }
            }];
    };
    if (![[NSUserDefaults wmf] wmf_didFinishLegacySavedArticleImageMigration]) {
        WMF_TECH_DEBT_TODO(This legacy migration can be removed after enough users upgrade to 5.5.0)
            [self migrateLegacyImagesInArticle:article
                                    completion:doneMigration];
    } else {
        doneMigration();
    }
}

- (void)migrateLegacyImagesInArticle:(MWKArticle *)article completion:(dispatch_block_t)completion {
    WMFImageController *imageController = [WMFImageController sharedInstance];
    NSArray<NSURL *> *legacyImageURLs = [article imageURLsForSaving];
    NSString *group = article.url.wmf_articleDatabaseKey;
    if (!group || !legacyImageURLs.count) {
        if (completion) {
            completion();
        }
        return;
    }
    [imageController migrateLegacyImageURLs:legacyImageURLs intoGroup:group completion:completion];
}

- (void)fetchAllImagesInArticle:(MWKArticle *)article failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    dispatch_block_t doneMigration = ^{
        NSArray *imageURLsForSaving = [article imageURLsForSaving];
        NSString *articleKey = article.url.wmf_articleDatabaseKey;
        if (!articleKey || imageURLsForSaving.count == 0) {
            success();
            return;
        }
        [self cacheImagesForArticleKey:articleKey withURLsInBackground:imageURLsForSaving failure:failure success:success];
    };
    if (![[NSUserDefaults wmf] wmf_didFinishLegacySavedArticleImageMigration]) {
        WMF_TECH_DEBT_TODO(This legacy migration can be removed after enough users upgrade to 5.0 .5)
            [self migrateLegacyImagesInArticle:article
                                    completion:doneMigration];
    } else {
        doneMigration();
    }
}

- (void)fetchGalleryDataForArticle:(MWKArticle *)article failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    WMF_TECH_DEBT_TODO(check whether on - disk image info matches what we are about to fetch)
    @weakify(self);

    [self fetchImageInfoForImagesInArticle:article
        failure:^(NSError *error) {
            failure(error);
        }
        success:^(NSArray *info) {
            @strongify(self);
            if (!self) {
                failure([NSError wmf_cancelledError]);
                return;
            }
            if (info.count == 0) {
                DDLogVerbose(@"No gallery images to fetch.");
                success();
                return;
            }

            NSArray *URLs = [info valueForKey:@"imageThumbURL"];
            [self cacheImagesForArticleKey:article.url.wmf_articleDatabaseKey withURLsInBackground:URLs failure:failure success:success];
        }];
}

- (void)fetchImageInfoForImagesInArticle:(MWKArticle *)article failure:(WMFErrorHandler)failure success:(WMFSuccessNSArrayHandler)success {
    NSArray<NSString *> *imageFileTitles =
        [MWKImage mapFilenamesFromImages:[article imagesForGallery]];

    if (imageFileTitles.count == 0) {
        DDLogVerbose(@"No image info to fetch.");
        success(imageFileTitles);
        return;
    }

    NSMutableArray *infoObjects = [NSMutableArray arrayWithCapacity:imageFileTitles.count];
    WMFTaskGroup *group = [WMFTaskGroup new];
    for (NSString *canonicalFilename in imageFileTitles) {
        [group enter];
        [self.imageInfoFetcher fetchGalleryInfoForImage:canonicalFilename
            fromSiteURL:article.url
            failure:^(NSError *_Nonnull error) {
                [group leave];
            }
            success:^(id _Nonnull object) {
                if (!object || [object isEqual:[NSNull null]]) {
                    [group leave];
                    return;
                }
                [infoObjects addObject:object];
                [group leave];
            }];
    }

    @weakify(self);
    [group waitInBackgroundAndNotifyOnQueue:self.accessQueue
                                  withBlock:^{
                                      @strongify(self);
                                      if (!self) {
                                          failure([NSError wmf_cancelledError]);
                                          return;
                                      }
                                      [self.dataStore saveImageInfo:infoObjects forArticleURL:article.url];
                                      success(infoObjects);
                                  }];
}

- (void)cacheImagesForArticleKey:(NSString *)articleKey withURLsInBackground:(NSArray<NSURL *> *)imageURLs failure:(void (^_Nonnull)(NSError *_Nonnull error))failure success:(void (^_Nonnull)(void))success {
    imageURLs = [imageURLs wmf_select:^BOOL(id obj) {
        return [obj isKindOfClass:[NSURL class]];
    }];

    if (!articleKey || [imageURLs count] == 0) {
        success();
        return;
    }

    [self.imageController permanentlyCacheInBackgroundWithUrls:imageURLs groupKey:articleKey failure:failure success:success];
}

#pragma mark - Cancellation

- (void)removeArticleWithURL:(NSURL *)URL completion:(dispatch_block_t)completion {
    [self.dataStore removeArticleWithURL:URL fromDiskWithCompletion:completion];
}

- (void)cancelFetchForArticleURL:(NSURL *)URL {
    WMFAssertMainThread(@"must be called on the main thread");
    DDLogVerbose(@"Canceling saved page download for title: %@", URL);
    [self.articleFetcher cancelFetchForArticleURL:URL];
    [self.fetchOperationsByArticleTitle removeObjectForKey:URL];
}

#pragma mark - Delegate Notification

/// Only invoke within accessQueue
- (void)didFetchArticle:(MWKArticle *__nullable)fetchedArticle
                    url:(NSURL *)url
                  error:(NSError *__nullable)error {
    WMFAssertMainThread(@"must be called on the main thread");

    //Uncomment when dropping iOS 9
    if (error) {
        // store errors for later reporting
        DDLogError(@"Failed to download saved page %@ due to error: %@", url, error);
        self.errorsByArticleTitle[url] = error;
    } else {
        DDLogInfo(@"Downloaded saved page: %@", url);
    }

    // stop tracking operation, effectively advancing the progress
    [self.fetchOperationsByArticleTitle removeObjectForKey:url];

    [self updateFetchesInProcessCount];

    WMFArticle *article = [self.dataStore fetchArticleWithURL:url];
    [article updatePropertiesForError:error];
    if (error) {
        if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
            NSDictionary *userInfo = @{WMFArticleSaveToDiskDidFailErrorKey: error, WMFArticleSaveToDiskDidFailArticleURLKey: url};
            [NSNotificationCenter.defaultCenter postNotificationName:WMFArticleSaveToDiskDidFailNotification object:nil userInfo:userInfo];
            [self stop];
            article.isDownloaded = NO;
        } else if ([error.domain isEqualToString:WMFNetworkingErrorDomain] && error.code == WMFNetworkingError_APIError && [error.userInfo[NSLocalizedFailureReasonErrorKey] isEqualToString:@"missingtitle"]) {
            article.isDownloaded = YES; // skip missing titles
        } else {
            article.isDownloaded = NO;
        }
    } else {
        article.isDownloaded = YES;
    }
    
    NSError *saveError = nil;
    [self.dataStore save:&saveError];
    if (saveError) {
        DDLogError(@"Error saving after saved articles fetch: %@", saveError);
    }
}

/// Only invoke within accessQueue
- (void)notifyDelegateIfFinished {
    //Uncomment when dropping iOS 9
    //dispatch_assert_queue_debug(self.accessQueue);
    if ([self.fetchOperationsByArticleTitle count] == 0) {
        NSError *reportedError;
        if ([self.errorsByArticleTitle count] > 0) {
            reportedError = [[self.errorsByArticleTitle allValues] firstObject];
        }

        [self.errorsByArticleTitle removeAllObjects];

        DDLogDebug(@"Finished downloading all saved pages!");

        [self finishWithError:reportedError
                  fetchedData:nil];
    }
}

@end

static NSString *const WMFSavedPageErrorDomain = @"WMFSavedPageErrorDomain";

@implementation NSError (SavedArticlesFetcherErrors)

+ (instancetype)wmf_savedPageImageDownloadError {
    return [NSError errorWithDomain:WMFSavedPageErrorDomain
                               code:1
                           userInfo:@{
                               NSLocalizedDescriptionKey: WMFLocalizedStringWithDefaultValue(@"saved-pages-image-download-error", nil, nil, @"Failed to download images for this saved page.", @"Error message shown when one or more images fails to save for offline use.")
                           }];
}

@end

NS_ASSUME_NONNULL_END
