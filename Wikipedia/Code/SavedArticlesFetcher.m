#import "SavedArticlesFetcher_Testing.h"

#import "Wikipedia-Swift.h"
#import "WMFArticleFetcher.h"
#import "MWKImageInfoFetcher.h"

#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKArticle.h"
#import "MWKImage+CanonicalFilenames.h"
#import "WMFImageURLParsing.h"
#import "WMFTaskGroup.h"
#import <WMF/WMF.h>

static DDLogLevel const WMFSavedArticlesFetcherLogLevel = DDLogLevelDebug;

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFSavedArticlesFetcherLogLevel

NS_ASSUME_NONNULL_BEGIN

@interface SavedArticlesFetcher ()

@property (nonatomic, strong, readwrite) dispatch_queue_t accessQueue;

@property (nonatomic, strong) MWKDataStore *dataStore;
@property (nonatomic, strong) MWKSavedPageList *savedPageList;
@property (nonatomic, strong) WMFArticleFetcher *articleFetcher;
@property (nonatomic, strong) WMFImageController *imageController;
@property (nonatomic, strong) MWKImageInfoFetcher *imageInfoFetcher;
@property (nonatomic, strong) WMFSavedPageSpotlightManager *spotlightManager;

@property (nonatomic, strong) NSMutableDictionary<NSURL *, NSURLSessionTask *> *fetchOperationsByArticleTitle;
@property (nonatomic, strong) NSMutableDictionary<NSURL *, NSError *> *errorsByArticleTitle;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore
                    savedPageList:(MWKSavedPageList *)savedPageList
                   articleFetcher:(WMFArticleFetcher *)articleFetcher
                  imageController:(WMFImageController *)imageController
                 imageInfoFetcher:(MWKImageInfoFetcher *)imageInfoFetcher NS_DESIGNATED_INITIALIZER;
@end

@implementation SavedArticlesFetcher

@dynamic fetchFinishedDelegate;

#pragma mark - NSObject

static SavedArticlesFetcher *_articleFetcher = nil;

- (void)dealloc {
    [self stop];
}

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore
                    savedPageList:(MWKSavedPageList *)savedPageList
                   articleFetcher:(WMFArticleFetcher *)articleFetcher
                  imageController:(WMFImageController *)imageController
                 imageInfoFetcher:(MWKImageInfoFetcher *)imageInfoFetcher {
    NSParameterAssert(dataStore);
    NSParameterAssert(savedPageList);
    NSParameterAssert(articleFetcher);
    NSParameterAssert(imageController);
    NSParameterAssert(imageInfoFetcher);
    self = [super init];
    if (self) {
        self.accessQueue = dispatch_queue_create("org.wikipedia.savedarticlesarticleFetcher.accessQueue", DISPATCH_QUEUE_SERIAL);
        self.fetchOperationsByArticleTitle = [NSMutableDictionary new];
        self.errorsByArticleTitle = [NSMutableDictionary new];
        self.dataStore = dataStore;
        self.articleFetcher = articleFetcher;
        self.imageController = imageController;
        self.savedPageList = savedPageList;
        self.imageInfoFetcher = imageInfoFetcher;
        self.spotlightManager = [[WMFSavedPageSpotlightManager alloc] initWithDataStore:self.dataStore];
    }
    return self;
}

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore
                    savedPageList:(MWKSavedPageList *)savedPageList {
    return [self initWithDataStore:dataStore
                     savedPageList:savedPageList
                    articleFetcher:[[WMFArticleFetcher alloc] initWithDataStore:dataStore]
                   imageController:[WMFImageController sharedInstance]
                  imageInfoFetcher:[[MWKImageInfoFetcher alloc] init]];
}

#pragma mark - Public

- (void)start {
    [self observeSavedPages];
}

- (void)stop {
    [self unobserveSavedPages];
}

#pragma mark - Observing

- (void)articleWasUpdated:(NSNotification *)note {
    WMFArticle *article = note.object;
    if (article.savedDate != nil && !article.isDownloaded) {
        NSURL *articleURL = article.URL;
        if (articleURL) {
            [self fetchUncachedArticleURLs:@[articleURL]];
        }
    } else if (article.savedDate == nil) {
        NSURL *articleURL = article.URL;
        if (articleURL) {
            [self cancelFetchForArticleURL:articleURL
                                completion:^{
                                }];
            if (article.isDownloaded) {
                [self removeArticleWithURL:articleURL
                                completion:^{
                                }];
                [self.spotlightManager removeFromIndexWithUrl:articleURL];
            }
        }
    }
}

- (void)observeSavedPages {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleWasUpdated:) name:WMFArticleUpdatedNotification object:nil];
}

- (void)unobserveSavedPages {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Fetch

- (void)fetchUncachedArticlesInSavedPages:(dispatch_block_t)completion {
    dispatch_block_t didFinishLegacyMigration = ^{
        NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
        if (![defaults wmf_didFinishLegacySavedArticleImageMigration]) {
            [defaults wmf_setDidFinishLegacySavedArticleImageMigration:YES];
            [self.imageController removeLegacyCache];
        }
        if (completion) {
            completion();
        }
    };
    if ([self.savedPageList numberOfItems] == 0) {
        didFinishLegacyMigration();
        return;
    }

    WMFTaskGroup *group = [WMFTaskGroup new];
    [group enter];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSFetchRequest *undownloadedRequest = [WMFArticle fetchRequest];
        undownloadedRequest.predicate = [NSPredicate predicateWithFormat:@"savedDate != nil && isDownloaded == NO"];
        NSError *undownloadedFetchError = nil;
        NSArray *undownloadedArticles = [self.dataStore.viewContext executeFetchRequest:undownloadedRequest error:&undownloadedFetchError];
        if (undownloadedFetchError) {
            DDLogError(@"Error fetching undownloaded saved articles: %@", undownloadedFetchError);
        }
        for (WMFArticle *article in undownloadedArticles) {
            @autoreleasepool {
                NSURL *articleURL = article.URL;
                if (!articleURL) {
                    continue;
                }
                [group enter];
                dispatch_async(self.accessQueue, ^{
                    [self fetchArticleURL:articleURL
                        failure:^(NSError *error) {
                            [group leave];
                        }
                        success:^{
                            [group leave];
                        }];
                });
            }
        }
        NSFetchRequest *downloadedRequest = [WMFArticle fetchRequest];
        downloadedRequest.predicate = [NSPredicate predicateWithFormat:@"savedDate == nil && isDownloaded == YES"];
        NSError *downloadedFetchError = nil;
        NSArray *articlesToDelete = [self.dataStore.viewContext executeFetchRequest:downloadedRequest error:&downloadedFetchError];
        if (downloadedFetchError) {
            DDLogError(@"Error fetching downloaded unsaved articles: %@", downloadedFetchError);
        }
        for (WMFArticle *article in articlesToDelete) {
            @autoreleasepool {
                NSURL *articleURL = article.URL;
                if (!articleURL) {
                    continue;
                }
                [group enter];
                [self cancelFetchForArticleURL:articleURL
                                    completion:^{
                                        [self removeArticleWithURL:articleURL
                                                        completion:^{
                                                            [group leave];
                                                        }];
                                    }];
            }
        }
        [group leave];
    });
    [group waitInBackgroundWithCompletion:didFinishLegacyMigration];
}

- (void)fetchUncachedArticleURLs:(NSArray<NSURL *> *)urls {
    if (!urls.count) {
        return;
    }
    for (NSURL *url in urls) {
        dispatch_async(self.accessQueue, ^{
            [self fetchArticleURL:url
                failure:^(NSError *error) {
                }
                success:^{
                    [self.spotlightManager addToIndexWithUrl:url];
                }];
        });
    }
}

- (void)fetchArticleURL:(NSURL *)articleURL failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
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
                dispatch_async(self.accessQueue, ^{
                    [self didFetchArticle:articleFromDisk url:articleURL error:error];
                    failure(error);
                });
            }
            success:^{
                dispatch_async(self.accessQueue, ^{
                    [self didFetchArticle:articleFromDisk url:articleURL error:nil];
                    success();
                });
            }];
    } else {
        self.fetchOperationsByArticleTitle[articleURL] =
            [self.articleFetcher fetchArticleForURL:articleURL
                saveToDisk:YES
                progress:NULL
                failure:^(NSError *_Nonnull error) {
                    dispatch_async(self.accessQueue, ^{
                        [self didFetchArticle:nil url:articleURL error:error];
                        failure(error);
                    });
                }
                success:^(MWKArticle *_Nonnull article) {
                    dispatch_async(self.accessQueue, ^{
                        [self downloadImageDataForArticle:article
                            failure:^(NSError *error) {
                                dispatch_async(self.accessQueue, ^{
                                    [self didFetchArticle:article url:articleURL error:error];
                                    failure(error);
                                });
                            }
                            success:^{
                                dispatch_async(self.accessQueue, ^{
                                    [self didFetchArticle:article url:articleURL error:nil];
                                    success();
                                });
                            }];
                    });
                }];
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
    if (![[NSUserDefaults wmf_userDefaults] wmf_didFinishLegacySavedArticleImageMigration]) {
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
    if (![[NSUserDefaults wmf_userDefaults] wmf_didFinishLegacySavedArticleImageMigration]) {
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

- (void)cancelFetchForSavedPages {
    BOOL wasFetching = self.fetchOperationsByArticleTitle.count > 0;
    [self.savedPageList enumerateItemsWithBlock:^(WMFArticle *_Nonnull entry, BOOL *_Nonnull stop) {
        dispatch_async(self.accessQueue, ^{
            [self cancelFetchForArticleURL:entry.URL
                                completion:^{
                                }];
        });
    }];
    if (wasFetching) {
        dispatch_async(self.accessQueue, ^{
            /*
               only notify delegate if deletion occurs during a download session. if deletion occurs
               after the fact, we don't need to inform delegate of completion
             */
            [self notifyDelegateIfFinished];
        });
    }
}

- (void)removeArticleWithURL:(NSURL *)URL completion:(dispatch_block_t)completion {
    [self.dataStore removeArticleWithURL:URL fromDiskWithCompletion:completion];
}

- (void)cancelFetchForArticleURL:(NSURL *)URL completion:(dispatch_block_t)completion {
    dispatch_async(self.accessQueue, ^{
        DDLogVerbose(@"Canceling saved page download for title: %@", URL);
        [self.articleFetcher cancelFetchForArticleURL:URL];
        [self.fetchOperationsByArticleTitle removeObjectForKey:URL];
        if (completion) {
            completion();
        }
    });
}

#pragma mark - Delegate Notification

/// Only invoke within accessQueue
- (void)didFetchArticle:(MWKArticle *__nullable)fetchedArticle
                    url:(NSURL *)url
                  error:(NSError *__nullable)error {
    //Uncomment when dropping iOS 9
    //dispatch_assert_queue_debug(self.accessQueue);
    if (error) {
        // store errors for later reporting
        DDLogError(@"Failed to download saved page %@ due to error: %@", url, error);
        self.errorsByArticleTitle[url] = error;
    } else {
        DDLogInfo(@"Downloaded saved page: %@", url);
    }

    // stop tracking operation, effectively advancing the progress
    [self.fetchOperationsByArticleTitle removeObjectForKey:url];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error) {
            WMFArticle *article = [self.dataStore fetchArticleWithURL:url];
            article.isDownloaded = YES;
            NSError *saveError = nil;
            [self.dataStore save:&saveError];
            if (saveError) {
                DDLogError(@"Error saving after saved articles fetch: %@", saveError);
            }
        }
        [self.fetchFinishedDelegate savedArticlesFetcher:self
                                             didFetchURL:url
                                                 article:fetchedArticle
                                                   error:error];
    });

    [self notifyDelegateIfFinished];
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

        DDLogInfo(@"Finished downloading all saved pages!");

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
