#import <Foundation/Foundation.h>

@class MWKDataStore;
@class WMFArticleDataStore;
@class MWKArticle;
@class AFHTTPSessionManager;

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
@property (nonatomic, strong, readonly) WMFArticleDataStore *previewStore;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore previewStore:(WMFArticleDataStore *)previewStore;

- (nullable NSURLSessionTask *)fetchArticleForURL:(NSURL *)articleURL progress:(WMFProgressHandler __nullable)progress failure:(WMFErrorHandler)failure success:(WMFArticleHandler)success;

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
- (nullable NSURLSessionTask *)fetchLatestVersionOfArticleWithURLIfNeeded:(NSURL *)URL
                                                                 progress:(WMFProgressHandler __nullable)progress
                                                                  failure:(WMFErrorHandler)failure
                                                                  success:(WMFArticleHandler)success;

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
                                                         progress:(WMFProgressHandler __nullable)progress
                                                          failure:(WMFErrorHandler)failure
                                                          success:(WMFArticleHandler)success;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
