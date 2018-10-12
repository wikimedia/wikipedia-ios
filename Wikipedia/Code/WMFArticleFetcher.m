#import "WMFArticleFetcher.h"
#import <WMF/WMF-Swift.h>

#if WMF_TWEAKS_ENABLED
#import <Tweaks/FBTweakInline.h>
#endif
//Tried not to do it, but we need it for the useageReports BOOL
//Plan to refactor settings into an another object, then we can remove this.
#import <WMF/SessionSingleton.h>

//AFNetworking
#import <WMF/MWNetworkActivityIndicatorManager.h>
#import <WMF/AFHTTPSessionManager+WMFConfig.h>
#import "WMFArticleRequestSerializer.h"
#import "WMFArticleResponseSerializer.h"

// Revisions
#import "WMFArticleRevisionFetcher.h"
#import "WMFArticleRevision.h"
#import "WMFRevisionQueryResults.h"

#import "Wikipedia-Swift.h"

//Models
#import <WMF/MWKSectionList.h>
#import <WMF/MWKSection.h>
#import <WMF/AFHTTPSessionManager+WMFCancelAll.h>
#import "WMFArticleBaseFetcher_Testing.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFArticleFetcherErrorDomain = @"WMFArticleFetcherErrorDomain";

NSString *const WMFArticleFetcherErrorCachedFallbackArticleKey = @"WMFArticleFetcherErrorCachedFallbackArticleKey";

@interface WMFArticleFetcher ()

@property (nonatomic, strong) NSMapTable *operationsKeyedByTitle;
@property (nonatomic, strong) dispatch_queue_t operationsQueue;

@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;
@property (nonatomic, strong) WMFArticleRevisionFetcher *revisionFetcher;

@property (nonatomic, strong) AFHTTPSessionManager *pageSummarySessionManager;

@end

@implementation WMFArticleFetcher

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {

        self.dataStore = dataStore;

        self.operationsKeyedByTitle = [NSMapTable strongToWeakObjectsMapTable];
        NSString *queueID = [NSString stringWithFormat:@"org.wikipedia.articlefetcher.accessQueue.%@", [[NSUUID UUID] UUIDString]];
        self.operationsQueue = dispatch_queue_create([queueID cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        self.operationManager = manager;
        self.operationManager.requestSerializer = [WMFArticleRequestSerializer serializer];
        self.operationManager.responseSerializer = [WMFArticleResponseSerializer serializer];

        self.pageSummarySessionManager = [AFHTTPSessionManager wmf_createDefaultManager];

        self.revisionFetcher = [[WMFArticleRevisionFetcher alloc] init];

        /*
         Setting short revision check timeouts, to ensure that poor connections don't drastically impact the case
         when cached article content is up to date.
         */
        //        FBTweakBind(self.revisionFetcher,
        //                    timeoutInterval,
        //                    @"Networking",
        //                    @"Article",
        //                    @"Revision Check Timeout",
        //                    0.8);
    }
    return self;
}

- (void)dealloc {
    [self.operationManager invalidateSessionCancelingTasks:YES];
    [self.pageSummarySessionManager invalidateSessionCancelingTasks:YES];
}

#pragma mark - Fetching

- (nullable NSURLSessionTask *)fetchArticleForURL:(NSURL *)articleURL
                                    useDesktopURL:(BOOL)useDeskTopURL
                                       saveToDisk:(BOOL)saveToDisk
                                         priority:(float)priority
                                         progress:(WMFProgressHandler __nullable)progress
                                          failure:(WMFErrorHandler)failure
                                          success:(WMFArticleHandler)success {
    NSString *title = articleURL.wmf_titleWithUnderscores;
    if (!title) {
        failure([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
        return nil;
    }

    // Force desktop domain if not Zero rated.
    if (![SessionSingleton sharedInstance].zeroConfigurationManager.isZeroRated) {
        useDeskTopURL = YES;
    }

    NSURL *url = useDeskTopURL ? [NSURL wmf_desktopAPIURLForURL:articleURL] : [NSURL wmf_mobileAPIURLForURL:articleURL];

    WMFTaskGroup *taskGroup = [WMFTaskGroup new];
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    __block id summaryResponse = nil;
    [taskGroup enter];
    [[WMFSession shared] fetchSummaryForArticleURL:articleURL
                                          priority:priority
                                 completionHandler:^(NSDictionary<NSString *, id> *_Nullable summary, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                                     summaryResponse = summary;
                                     [taskGroup leave];
                                 }];

    //    __block id mediaResponse = nil;
    //    [taskGroup enter];
    //    [[WMFSession shared] fetchMediaForArticleURL:articleURL
    //                                          priority:priority
    //                                 completionHandler:^(NSDictionary<NSString *, id> *_Nullable media, NSURLResponse *_Nullable response, NSError *_Nullable error) {
    //                                     mediaResponse = media;
    //                                     [taskGroup leave];
    //                                 }];

    __block id articleResponse = nil;
    __block NSError *articleError = nil;
    [taskGroup enter];
    NSURLSessionDataTask *operation = [self.operationManager GET:url.absoluteString
        parameters:articleURL
        progress:^(NSProgress *_Nonnull downloadProgress) {
            if (progress) {
                CGFloat currentProgress = downloadProgress.fractionCompleted;
                dispatchOnMainQueue(^{
                    progress(currentProgress);
                });
            }
        }
        success:^(NSURLSessionDataTask *operation, id response) {
            articleResponse = response;
            [taskGroup leave];
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            articleError = error;
            [taskGroup leave];
        }];

    operation.priority = priority;
    [self trackOperation:operation forArticleURL:articleURL];

    [taskGroup waitInBackgroundAndNotifyOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
                                      withBlock:^{
                                          [[MWNetworkActivityIndicatorManager sharedManager] pop];
                                          if (articleResponse && [articleResponse isKindOfClass:[NSDictionary class]]) {
                                              NSMutableDictionary *mutableArticleResponse = [articleResponse mutableCopy];
                                              //[mutableArticleResponse setValue:mediaResponse forKey:@"media"];
                                              if (!articleResponse[@"coordinates"] && summaryResponse[@"coordinates"]) {
                                                  mutableArticleResponse[@"coordinates"] = summaryResponse[@"coordinates"];
                                              }

                                              NSURL *updatedArticleURL = articleURL;
                                              NSString *redirectedTitle = articleResponse[@"redirected"];
                                              if (redirectedTitle) {
                                                  updatedArticleURL = [articleURL wmf_URLWithTitle:redirectedTitle];
                                              }

                                              articleResponse = mutableArticleResponse;

                                              NSError *articleSerializationError = nil;
                                              MWKArticle *mwkArticle = [self serializedArticleWithURL:updatedArticleURL response:articleResponse error:&articleSerializationError];

                                              if (articleSerializationError) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      failure(articleSerializationError);
                                                  });
                                                  return;
                                              }
                                              [self.dataStore asynchronouslyCacheArticle:mwkArticle
                                                                                  toDisk:saveToDisk
                                                                              completion:^(NSError *_Nonnull articleCacheError) {
                                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                                      NSManagedObjectContext *moc = self.dataStore.viewContext;
                                                                                      WMFArticle *article = [moc fetchOrCreateArticleWithURL:updatedArticleURL];
                                                                                      article.isExcludedFromFeed = mwkArticle.ns != 0 || updatedArticleURL.wmf_isMainPage;
                                                                                      article.isDownloaded = NO; //isDownloaded == NO so that any new images added to the article will be downloaded by the SavedArticlesFetcher
                                                                                      article.wikidataID = mwkArticle.wikidataId;
                                                                                      if (summaryResponse) {
                                                                                          [article updateWithSummary:summaryResponse];
                                                                                      }
                                                                                      NSError *saveError = nil;
                                                                                      if ([moc hasChanges] && ![moc save:&saveError]) {
                                                                                          DDLogError(@"Error saving after updating article: %@", saveError);
                                                                                      }
                                                                                      if (articleCacheError) {
                                                                                          failure(articleCacheError);
                                                                                      } else {
                                                                                          success(mwkArticle);
                                                                                      }
                                                                                  });
                                                                              }];
                                          } else {
                                              if (!articleError) {
                                                  articleError = [NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType userInfo:@{}];
                                              }
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  failure(articleError);
                                              });
                                          }
                                      }];

    return operation;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

#pragma mark - Operation Tracking / Cancelling

- (nullable NSURLSessionDataTask *)trackedOperationForArticleURL:(NSURL *)articleURL {
    if ([articleURL.wmf_title length] == 0) {
        return nil;
    }

    __block NSURLSessionDataTask *op = nil;

    dispatch_sync(self.operationsQueue, ^{
        op = [self.operationsKeyedByTitle objectForKey:articleURL];
    });

    return op;
}

- (void)trackOperation:(NSURLSessionDataTask *)operation forArticleURL:(NSURL *)articleURL {
    if ([articleURL.wmf_title length] == 0) {
        return;
    }

    dispatch_sync(self.operationsQueue, ^{
        [self.operationsKeyedByTitle setObject:operation forKey:articleURL];
    });
}

- (BOOL)isFetchingArticleForURL:(NSURL *)articleURL {
    return [self trackedOperationForArticleURL:articleURL] != nil;
}

- (void)cancelFetchForArticleURL:(NSURL *)articleURL {
    [[self trackedOperationForArticleURL:articleURL] cancel];
}

- (void)cancelAllFetches {
    [self.operationManager wmf_cancelAllTasks];
    [self.pageSummarySessionManager wmf_cancelAllTasks];
}

- (nullable MWKArticle *)serializedArticleWithURL:(NSURL *)url response:(NSDictionary *)response error:(NSError **)error {
    MWKArticle *article = [[MWKArticle alloc] initWithURL:url dataStore:self.dataStore];
    @try {
        [article importMobileViewJSON:response];
        if ([article.url.wmf_language isEqualToString:@"zh"]) {
            NSString *header = [NSLocale wmf_acceptLanguageHeaderForPreferredLanguages];
            article.acceptLanguageRequestHeader = header;
        }
        return article;
    } @catch (NSException *e) {
        DDLogError(@"Failed to import article data. Response: %@. Error: %@", response, e);
        if (error) {
            *error = [NSError wmf_serializeArticleErrorWithReason:[e reason]];
        }
        return nil;
    }
}

- (nullable NSURLSessionTask *)fetchLatestVersionOfArticleWithURL:(NSURL *)url
                                                    forceDownload:(BOOL)forceDownload
                                                       saveToDisk:(BOOL)saveToDisk
                                                         priority:(float)priority
                                                         progress:(WMFProgressHandler __nullable)progress
                                                          failure:(WMFErrorHandler)failure
                                                          success:(WMFArticleHandler)success {

    NSParameterAssert(url.wmf_title);
    if (!url.wmf_title) {
        DDLogError(@"Can't fetch nil title, cancelling implicitly.");
        failure([NSError wmf_cancelledError]);
        return nil;
    }

    MWKArticle *cachedArticle;
    BOOL isChinese = [url.wmf_language isEqualToString:@"zh"];

    if (!forceDownload || isChinese) {
        cachedArticle = [self.dataStore existingArticleWithURL:url];
    }

    BOOL forceDownloadForMismatchedHeader = NO;

    if (isChinese) {
        NSString *header = [NSLocale wmf_acceptLanguageHeaderForPreferredLanguages];
        if (![cachedArticle.acceptLanguageRequestHeader isEqualToString:header]) {
            forceDownloadForMismatchedHeader = YES;
        }
    }

    failure = ^(NSError *error) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo ?: @{}];
        userInfo[WMFArticleFetcherErrorCachedFallbackArticleKey] = cachedArticle;
        failure([NSError errorWithDomain:error.domain
                                    code:error.code
                                userInfo:userInfo]);
    };

    @weakify(self);
    NSURLSessionTask *task;
    if (forceDownload || forceDownloadForMismatchedHeader || !cachedArticle || !cachedArticle.revisionId || [cachedArticle isMain]) {
        if (forceDownload) {
            DDLogInfo(@"Forcing Download for %@, fetching immediately", url);
        } else if (!cachedArticle) {
            DDLogInfo(@"No cached article found for %@, fetching immediately.", url);
        } else if (!cachedArticle.revisionId) {
            DDLogInfo(@"Cached article for %@ doesn't have revision ID, fetching immediately.", url);
        } else if (forceDownloadForMismatchedHeader) {
            DDLogInfo(@"Language Headers are mismatched for %@, assume simplified vs traditional as changed, fetching immediately.", url);
        } else {
            //Main pages dont neccesarily have revisions every day. We can't rely on the revision check
            DDLogInfo(@"Cached article for main page: %@, fetching immediately.", url);
        }
        task = [self fetchArticleForURL:url saveToDisk:saveToDisk priority:priority progress:progress failure:failure success:success];
    } else {
        task = [self.revisionFetcher fetchLatestRevisionsForArticleURL:url
                                                           resultLimit:1
                                                    endingWithRevision:cachedArticle.revisionId.unsignedIntegerValue
                                                               failure:failure
                                                               success:^(id _Nonnull results) {
                                                                   @strongify(self);
                                                                   if (!self) {
                                                                       failure([NSError wmf_cancelledError]);
                                                                       return;
                                                                   } else if ([[results revisions].firstObject.revisionId isEqualToNumber:cachedArticle.revisionId]) {
                                                                       DDLogInfo(@"Returning up-to-date local revision of %@", url);
                                                                       if (progress) {
                                                                           progress(1.0);
                                                                       }
                                                                       success(cachedArticle);
                                                                       return;
                                                                   } else {
                                                                       [self fetchArticleForURL:url saveToDisk:saveToDisk priority:priority progress:progress failure:failure success:success];
                                                                       return;
                                                                   }
                                                               }];
    }
    task.priority = priority;
    return task;
}

- (nullable NSURLSessionTask *)fetchLatestVersionOfArticleWithURLIfNeeded:(NSURL *)url
                                                               saveToDisk:(BOOL)saveToDisk
                                                                 priority:(float)priority
                                                                 progress:(WMFProgressHandler __nullable)progress
                                                                  failure:(WMFErrorHandler)failure
                                                                  success:(WMFArticleHandler)success {
    return [self fetchLatestVersionOfArticleWithURL:url forceDownload:NO saveToDisk:saveToDisk priority:priority progress:progress failure:failure success:success];
}

- (nullable NSURLSessionTask *)fetchArticleForURL:(NSURL *)articleURL saveToDisk:(BOOL)saveToDisk priority:(float)priority progress:(WMFProgressHandler __nullable)progress failure:(WMFErrorHandler)failure success:(WMFArticleHandler)success {
    NSAssert(articleURL.wmf_title != nil, @"Title text nil");
    NSAssert(self.dataStore != nil, @"Store nil");
    NSAssert(self.operationManager != nil, @"Manager nil");
    return [self fetchArticleForURL:articleURL useDesktopURL:NO saveToDisk:saveToDisk priority:priority progress:progress failure:failure success:success];
}

@end

NS_ASSUME_NONNULL_END
