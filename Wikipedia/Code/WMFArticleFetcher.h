@import Foundation;
@class MWKDataStore;
@class MWKArticle;
@import WMF.WMFBlockDefinitions;
@import WMF.WMFLegacyFetcher;

NS_ASSUME_NONNULL_BEGIN

/**
 *  @see fetchLatestVersionOfTitleIfNeeded:
 */
extern NSString *const WMFArticleFetcherErrorCachedFallbackArticleKey;

@interface WMFArticleFetcher : WMFLegacyFetcher

- (void)cancelFetchForArticleURL:(NSURL *)articleURL;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

- (nullable NSURLSessionTask *)fetchArticleForURL:(NSURL *)articleURL saveToDisk:(BOOL)saveToDisk priority:(float)priority failure:(WMFErrorHandler)failure success:(WMFArticleHandler)success;

/**
 *  Fetch the latest version of @c URL, if the locally stored revision is not the latest.
 *
 *  @param title    The title to fetch.
 *
 *  @param failure block If there was a cached article, and an error was encountered,
 *          the error's @c userInfo will contain the cached article for the key @c WMFArticleFetcherErrorCachedFallbackArticleKey
 *  @param success block
 */
- (nullable NSURLSessionTask *)fetchLatestVersionOfArticleWithURLIfNeeded:(NSURL *)URL saveToDisk:(BOOL)saveToDisk priority:(float)priority failure:(WMFErrorHandler)failure success:(WMFArticleHandler)success;

/**
 *  Fetch the latest version of @c URL, if the locally stored revision is not the latest. If forceDownload is passed, the latest version is always downloaded ignoring any cahced data
 *
 *  @param title    The title to fetch.
 *  @param forceDownload If YES, the article will be downloaded even if it is already cached.
 *
 *  @param failure block If there was a cached article, and an error was encountered,
 *          the error's @c userInfo will contain the cached article for the key @c WMFArticleFetcherErrorCachedFallbackArticleKey
 *  @param success block
 */
- (nullable NSURLSessionTask *)fetchLatestVersionOfArticleWithURL:(NSURL *)URL
                                                    forceDownload:(BOOL)forceDownload
                                                       saveToDisk:(BOOL)saveToDisk
                                                         priority:(float)priority
                                                          failure:(WMFErrorHandler)failure
                                                          success:(WMFArticleHandler)success;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
