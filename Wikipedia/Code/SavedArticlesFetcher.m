#import "SavedArticlesFetcher_Testing.h"

#import "Wikipedia-Swift.h"
#import "WMFArticleFetcher.h"
#import "MWKImageInfoFetcher.h"

#import "MWKDataStore.h"
#import "WMFArticleDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKArticle.h"
#import "MWKImage+CanonicalFilenames.h"
#import "WMFURLCache.h"
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
                     previewStore:(WMFArticleDataStore *)previewStore
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
                     previewStore:(WMFArticleDataStore *)previewStore
                    savedPageList:(MWKSavedPageList *)savedPageList
                   articleFetcher:(WMFArticleFetcher *)articleFetcher
                  imageController:(WMFImageController *)imageController
                 imageInfoFetcher:(MWKImageInfoFetcher *)imageInfoFetcher {
    NSParameterAssert(dataStore);
    NSParameterAssert(previewStore);
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
                     previewStore:(WMFArticleDataStore *)previewStore
                    savedPageList:(MWKSavedPageList *)savedPageList {
    return [self initWithDataStore:dataStore
                      previewStore:previewStore
                     savedPageList:savedPageList
                    articleFetcher:[[WMFArticleFetcher alloc] initWithDataStore:dataStore previewStore:previewStore]
                   imageController:[WMFImageController sharedInstance]
                  imageInfoFetcher:[[MWKImageInfoFetcher alloc] init]];
}

#pragma mark - Public

- (void)start {
    [self fetchUncachedArticlesInSavedPages];
    [self observeSavedPages];
}

- (void)stop {
    [self unobserveSavedPages];
    [self cancelFetchForSavedPages];
}

#pragma mark - Observing

- (void)itemWasUpdated:(NSNotification *)note {
    NSURL *url = note.userInfo[MWKURLKey];
    if (!url) {
        return;
    }
    NSDate *savedDate = note.userInfo[MWKSavedDateKey];
    if (savedDate) {
        [self fetchUncachedArticleURLs:@[url]];
    } else {
        [self cancelFetchForArticleURL:url];
        [self.spotlightManager removeFromIndexWithUrl:url];
    }
}

- (void)observeSavedPages {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemWasUpdated:) name:MWKItemUpdatedNotification object:nil];
}

- (void)unobserveSavedPages {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Fetch

- (void)fetchUncachedArticlesInSavedPages {
    dispatch_block_t didFinishLegacyMigration = ^{
        [[NSUserDefaults wmf_userDefaults] wmf_setDidFinishLegacySavedArticleImageMigration:YES];
    };
    if ([self.savedPageList numberOfItems] == 0) {
        didFinishLegacyMigration();
        return;
    }

    WMFTaskGroup *group = [WMFTaskGroup new];
    [self.savedPageList enumerateItemsWithBlock:^(WMFArticle *_Nonnull entry, BOOL *_Nonnull stop) {
        [group enter];
        dispatch_async(self.accessQueue, ^{
            @autoreleasepool {
                NSURL *articleURL = [NSURL URLWithString:entry.key];
                if (articleURL) {
                    [self fetchArticleURL:articleURL
                        failure:^(NSError *error) {
                            [group leave];
                        }
                        success:^{
                            [group leave];
                        }];
                }
            }
        });
    }];
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
    @weakify(self);
    if (articleFromDisk.isCached) {
        // only fetch images if article was cached
        [self downloadImageDataForArticle:articleFromDisk failure:failure success:success];
    } else {
        self.fetchOperationsByArticleTitle[articleURL] =
            [self.articleFetcher fetchArticleForURL:articleURL
                progress:NULL
                failure:^(NSError *_Nonnull error) {
                    if (!self) {
                        return;
                    }
                    dispatch_async(self.accessQueue, ^{
                        [self didFetchArticle:nil url:articleURL error:error];
                    });
                }
                success:^(MWKArticle *_Nonnull article) {
                    dispatch_async(self.accessQueue, ^{
                        @strongify(self);
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
                //NOTE: turning off gallery image fetching as users are potentially downloading large amounts of data up front when upgrading to a new version of the app.
                //        [self fetchGalleryDataForArticle:article failure:failure success:success];
                if (success) {
                    success();
                }
            }];
    };
    if (![[NSUserDefaults wmf_userDefaults] wmf_didFinishLegacySavedArticleImageMigration]) {
        WMF_TECH_DEBT_TODO(This legacy migration can be removed after enough users upgrade to 5.0.5)
            [self migrateLegacyImagesInArticle:article
                                    completion:doneMigration];
    } else {
        doneMigration();
    }
}

- (void)migrateLegacyImagesInArticle:(MWKArticle *)article completion:(dispatch_block_t)completion {
    //  Copies saved article images cached by versions 5.0.4 and older to the locations where 5.0.5 and newer are looking for them. Previously, the app cached at the width of the largest image in the srcset. Currently, we request a thumbnail at wmf_articleImageWidthForScale (or original if it's narrower than that width). By copying from the old size to the new expected sizes, we ensure that articles saved with these older versions will still have images availble offline in the newer versions.
    if (completion) {
        completion();
    }
//    WMFImageController *imageController = [WMFImageController sharedInstance];
//    NSArray *legacyImageURLs = [self.dataStore legacyImageURLsForArticle:article];
//    NSInteger articleImageWidth = [[UIScreen mainScreen] wmf_articleImageWidthForScale];
//    WMFTaskGroup *group = [WMFTaskGroup new];
//    for (NSURL *legacyImageURL in legacyImageURLs) {
//        @autoreleasepool {
//            NSString *legacyImageURLString = legacyImageURL.absoluteString;
//            NSInteger width = WMFParseSizePrefixFromSourceURL(legacyImageURLString);
//            if (width == articleImageWidth || width == NSNotFound) {
//                continue;
//            }
//
//            if (legacyImageURL == nil) {
//                continue;
//            }
//
//            [group enter];
//            [imageController hasDataOnDiskForImageWithURL:legacyImageURL
//                                               completion:^(BOOL hasLegacyImageData) {
//                                                   if (!hasLegacyImageData) {
//                                                       [group leave];
//                                                       return;
//                                                   }
//
//                                                   NSURL *cachedFileURL = [NSURL fileURLWithPath:[imageController cachePathForImageWithURL:legacyImageURL] isDirectory:NO];
//
//                                                   if (cachedFileURL == nil) {
//                                                       [group leave];
//                                                       return;
//                                                   }
//
//                                                   NSString *imageExtension = [legacyImageURL pathExtension];
//                                                   NSString *imageMIMEType = [imageExtension wmf_asMIMEType];
//
//                                                   NSString *imageURLStringAtArticleWidth = WMFChangeImageSourceURLSizePrefix(legacyImageURLString, articleImageWidth);
//                                                   NSURL *imageURLAtArticleWidth = [NSURL URLWithString:imageURLStringAtArticleWidth];
//
//                                                   if (imageURLAtArticleWidth == nil) {
//                                                       [group leave];
//                                                       return;
//                                                   }
//
//                                                   [group enter];
//                                                   [imageController hasDataOnDiskForImageWithURL:imageURLAtArticleWidth
//                                                                                      completion:^(BOOL hasArticleWithData) {
//                                                                                          if (hasArticleWithData) {
//                                                                                              [group leave];
//                                                                                              return;
//                                                                                          }
//
//                                                                                          [imageController cacheImageFromFileURL:cachedFileURL forURL:imageURLAtArticleWidth MIMEType:imageMIMEType];
//                                                                                          [group leave];
//                                                                                      }];
//
//                                                   NSString *originalImageURLString = WMFOriginalImageURLStringFromURLString(legacyImageURLString);
//                                                   NSURL *originalImageURL = [NSURL URLWithString:originalImageURLString];
//                                                   [group enter];
//                                                   [imageController hasDataOnDiskForImageWithURL:originalImageURL
//                                                                                      completion:^(BOOL hasOriginalData) {
//                                                                                          if (hasOriginalData) {
//                                                                                              [group leave];
//                                                                                              return;
//                                                                                          }
//                                                                                          [imageController cacheImageFromFileURL:cachedFileURL forURL:originalImageURL MIMEType:imageMIMEType];
//                                                                                          [group leave];
//                                                                                      }];
//
//                                                   [group leave];
//                                               }];
//        }
//    }
//    [group waitInBackgroundWithTimeout:10 completion:completion];
}

- (void)fetchAllImagesInArticle:(MWKArticle *)article failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    dispatch_block_t doneMigration = ^{
        //Move any images already cached in the shared URL cache to our own cache (WMFImageController)
        WMFURLCache *cache = (WMFURLCache *)[NSURLCache sharedURLCache];
        [cache permanentlyCacheImagesForArticle:article];

        //Download any images that aren't cached
        NSArray<NSURL *> *URLs = [[article allImageURLs] allObjects];
        [self cacheImagesForArticleKey:article.url.wmf_articleDatabaseKey withURLsInBackground:URLs failure:failure success:success];
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
    [group waitInBackgroundAndNotifyOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
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
            [self cancelFetchForArticleURL:entry.URL];
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

- (void)cancelFetchForArticleURL:(NSURL *)URL {
    dispatch_async(self.accessQueue, ^{
        DDLogVerbose(@"Canceling saved page download for title: %@", URL);
        [self.articleFetcher cancelFetchForArticleURL:URL];
        [self.fetchOperationsByArticleTitle removeObjectForKey:URL];
        [self.imageController removePermanentlyCachedImagesWithGroupKey:URL.wmf_articleDatabaseKey];
    });
}

#pragma mark - Delegate Notification

/// Only invoke within accessQueue
- (void)didFetchArticle:(MWKArticle *__nullable)fetchedArticle
                    url:(NSURL *)url
                  error:(NSError *__nullable)error {
    dispatch_assert_queue_debug(self.accessQueue);
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
        [self.fetchFinishedDelegate savedArticlesFetcher:self
                                             didFetchURL:url
                                                 article:fetchedArticle
                                                   error:error];
    });

    [self notifyDelegateIfFinished];
}

/// Only invoke within accessQueue
- (void)notifyDelegateIfFinished {
    dispatch_assert_queue_debug(self.accessQueue);
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
                               NSLocalizedDescriptionKey: MWLocalizedString(@"saved-pages-image-download-error", nil)
                           }];
}

@end

NS_ASSUME_NONNULL_END
