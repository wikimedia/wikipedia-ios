#import "WMFArticleFetcher.h"

#import <Tweaks/FBTweakInline.h>

//Tried not to do it, but we need it for the useageReports BOOL
//Plan to refactor settings into an another object, then we can remove this.
#import "SessionSingleton.h"
#import "WMFArticleDataStore.h"

//AFNetworking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "WMFArticleRequestSerializer.h"
#import "WMFArticleResponseSerializer.h"

// Revisions
#import "WMFArticleRevisionFetcher.h"
#import "WMFArticleRevision.h"
#import "WMFRevisionQueryResults.h"

#import "Wikipedia-Swift.h"

//Models
#import "MWKSectionList.h"
#import "MWKSection.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"
#import "WMFArticleBaseFetcher_Testing.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFArticleFetcherErrorDomain = @"WMFArticleFetcherErrorDomain";

NSString *const WMFArticleFetcherErrorCachedFallbackArticleKey = @"WMFArticleFetcherErrorCachedFallbackArticleKey";

@interface WMFArticleFetcher ()

@property (nonatomic, strong) NSMapTable *operationsKeyedByTitle;
@property (nonatomic, strong) dispatch_queue_t operationsQueue;

@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;
@property (nonatomic, strong, readwrite) WMFArticleDataStore *previewStore;
@property (nonatomic, strong) WMFArticleRevisionFetcher *revisionFetcher;

@end

@implementation WMFArticleFetcher

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore previewStore:(WMFArticleDataStore *)previewStore {
    NSParameterAssert(dataStore);
    NSParameterAssert(previewStore);
    self = [super init];
    if (self) {

        self.dataStore = dataStore;
        self.previewStore = previewStore;

        self.operationsKeyedByTitle = [NSMapTable strongToWeakObjectsMapTable];
        NSString *queueID = [NSString stringWithFormat:@"org.wikipedia.articlefetcher.accessQueue.%@", [[NSUUID UUID] UUIDString]];
        self.operationsQueue = dispatch_queue_create([queueID cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        self.operationManager = manager;
        self.operationManager.requestSerializer = [WMFArticleRequestSerializer serializer];
        self.operationManager.responseSerializer = [WMFArticleResponseSerializer serializer];

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

#pragma mark - Fetching

- (nullable NSURLSessionTask *)fetchArticleForURL:(NSURL *)articleURL
                                    useDesktopURL:(BOOL)useDeskTopURL
                                         progress:(WMFProgressHandler __nullable)progress
                                          failure:(WMFErrorHandler)failure
                                          success:(WMFArticleHandler)success {
    if (!articleURL.wmf_title) {
        failure([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
        return nil;
    }

    // Force desktop domain if not Zero rated.
    if (![SessionSingleton sharedInstance].zeroConfigurationManager.isZeroRated) {
        useDeskTopURL = YES;
    }

    NSURL *url = useDeskTopURL ? [NSURL wmf_desktopAPIURLForURL:articleURL] : [NSURL wmf_mobileAPIURLForURL:articleURL];

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
            dispatchOnBackgroundQueue(^{
                [[MWNetworkActivityIndicatorManager sharedManager] pop];
                MWKArticle *article = [self serializedArticleWithURL:articleURL response:response];
                [self.dataStore asynchronouslyCacheArticle:article];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.previewStore addPreviewWithURL:articleURL updatedWithArticle:article];
                    success(article);
                });
            });
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            if ([url isEqual:[NSURL wmf_mobileAPIURLForURL:articleURL]] && [error wmf_shouldFallbackToDesktopURLError]) {
                [self fetchArticleForURL:articleURL useDesktopURL:YES progress:progress failure:failure success:success];
            } else {
                [[MWNetworkActivityIndicatorManager sharedManager] pop];
                failure(error);
            }
        }];

    [self trackOperation:operation forArticleURL:articleURL];
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
}

- (id)serializedArticleWithURL:(NSURL *)url response:(NSDictionary *)response {
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
        return [NSError wmf_serializeArticleErrorWithReason:[e reason]];
    }
}

- (nullable NSURLSessionTask *)fetchLatestVersionOfArticleWithURL:(NSURL *)url
                                                    forceDownload:(BOOL)forceDownload
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
        task = [self fetchArticleForURL:url progress:progress failure:failure success:success];
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
                                                                       [self fetchArticleForURL:url progress:progress failure:failure success:success];
                                                                       return;
                                                                   }
                                                               }];
    }

    return task;
}

- (nullable NSURLSessionTask *)fetchLatestVersionOfArticleWithURLIfNeeded:(NSURL *)url
                                                                 progress:(WMFProgressHandler __nullable)progress
                                                                  failure:(WMFErrorHandler)failure
                                                                  success:(WMFArticleHandler)success {
    return [self fetchLatestVersionOfArticleWithURL:url forceDownload:NO progress:progress failure:failure success:success];
}

- (nullable NSURLSessionTask *)fetchArticleForURL:(NSURL *)articleURL progress:(WMFProgressHandler __nullable)progress failure:(WMFErrorHandler)failure success:(WMFArticleHandler)success {
    NSAssert(articleURL.wmf_title != nil, @"Title text nil");
    NSAssert(self.dataStore != nil, @"Store nil");
    NSAssert(self.operationManager != nil, @"Manager nil");
    return [self fetchArticleForURL:articleURL useDesktopURL:NO progress:progress failure:failure success:success];
}

@end

NS_ASSUME_NONNULL_END
