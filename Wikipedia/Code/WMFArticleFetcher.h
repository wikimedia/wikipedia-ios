@import Foundation;
@class MWKDataStore;
@class MWKArticle;
@class AFHTTPSessionManager;
@import WMF.WMFBlockDefinitions;

NS_ASSUME_NONNULL_BEGIN

/**
 *  @see fetchLatestVersionOfTitleIfNeeded:progress:
 */
extern NSString *const WMFArticleFetcherErrorCachedFallbackArticleKey;

@interface WMFArticleFetcher : NSObject

- (BOOL)isFetchingArticleForURL:(NSURL *)articleURL;
- (void)cancelFetchForArticleURL:(NSURL *)articleURL;
- (void)cancelAllFetches;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

- (nullable NSURLSessionTask *)fetchArticleForURL:(NSURL *)articleURL saveToDisk:(BOOL)saveToDisk priority:(float)priority progress:(WMFProgressHandler __nullable)progress failure:(WMFErrorHandler)failure success:(WMFArticleHandler)success;

/**
 *  Fetch the latest version of @c URL, if the locally stored revision is not the latest.
 *
 *  @param title    The title to fetch.
 *  @param progress Block which will be invoked with download progress.
 *
 *  @param failure block If there was a cached article, and an error was encountered,
 *          the error's @c userInfo will contain the cached article for the key @c WMFArticleFetcherErrorCachedFallbackArticleKey
 *  @param success block
 */
- (nullable NSURLSessionTask *)fetchLatestVersionOfArticleWithURLIfNeeded:(NSURL *)URL saveToDisk:(BOOL)saveToDisk priority:(float)priority progress:(WMFProgressHandler __nullable)progress failure:(WMFErrorHandler)failure success:(WMFArticleHandler)success;

/**
 *  Fetch the latest version of @c URL, if the locally stored revision is not the latest. If forceDownload is passed, the latest version is always downloaded ignoring any cahced data
 *
 *  @param title    The title to fetch.
 *  @param forceDownload If YES, the article will be downloaded even if it is already cached.
 *  @param progress Block which will be invoked with download progress.
 *
 *  @param failure block If there was a cached article, and an error was encountered,
 *          the error's @c userInfo will contain the cached article for the key @c WMFArticleFetcherErrorCachedFallbackArticleKey
 *  @param success block
 */
- (nullable NSURLSessionTask *)fetchLatestVersionOfArticleWithURL:(NSURL *)URL
                                                    forceDownload:(BOOL)forceDownload
                                                       saveToDisk:(BOOL)saveToDisk
                                                         priority:(float)priority
                                                         progress:(WMFProgressHandler __nullable)progress
                                                          failure:(WMFErrorHandler)failure
                                                          success:(WMFArticleHandler)success;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
