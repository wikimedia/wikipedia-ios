#import <Foundation/Foundation.h>

@class MWKDataStore;
@class MWKArticle;
@class AFHTTPSessionManager;

NS_ASSUME_NONNULL_BEGIN

/**
 *  @see fetchLatestVersionOfTitleIfNeeded:progress:
 */
extern NSString *const WMFArticleFetcherErrorCachedFallbackArticleKey;

/* Temporary base class to hold common response serialization logic.
 * This can be removed when response serialization is moved into the
 * AFNetworking Serializers. See WMFArticleSerializer for more info.
 */
@interface WMFArticleBaseFetcher : NSObject

- (BOOL)isFetchingArticleForURL:(NSURL *)articleURL;
- (void)cancelFetchForArticleURL:(NSURL *)articleURL;
- (void)cancelAllFetches;

@end

@interface WMFArticleFetcher : WMFArticleBaseFetcher

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

//Fullfilled promise returns MWKArticle
- (AnyPromise *)fetchArticleForURL:(NSURL *)articleURL progress:(WMFProgressHandler __nullable)progress;

/**
 *  Fetch the latest version of @c URL, if the locally stored revision is not the latest.
 *
 *  @param title    The title to fetch.
 *  @param progress Block which will be invoked with download progress.
 *
 *  @return A promise which resolves to an article object. If there was a cached article, and an error was encountered,
 *          the error's @c userInfo will contain the cached article for the key @c WMFArticleFetcherErrorCachedFallbackArticleKey.
 */
- (AnyPromise *)fetchLatestVersionOfArticleWithURLIfNeeded:(NSURL *)URL
                                                  progress:(WMFProgressHandler __nullable)progress;

/**
 *  Fetch the latest version of @c URL, if the locally stored revision is not the latest. If forceDownload is passed, the latest version is always downloaded ignoring any cahced data
 *
 *  @param title    The title to fetch.
 *  @param forceDownload If YES, the article will be downloaded even if it is already cached.
 *  @param progress Block which will be invoked with download progress.
 *
 *  @return A promise which resolves to an article object. If there was a cached article, and an error was encountered,
 *          the error's @c userInfo will contain the cached article for the key @c WMFArticleFetcherErrorCachedFallbackArticleKey. */
- (AnyPromise *)fetchLatestVersionOfArticleWithURL:(NSURL *)URL
                                     forceDownload:(BOOL)forceDownload
                                          progress:(WMFProgressHandler __nullable)progress;

@property (nonatomic, assign, readonly) BOOL isFetching;


/**
 *  Save the @c article asynchronously. If an existing save operation exists for this article or an article with the same URL, it will be cancelled and re-added with this copy of the article.
 *
 *  @param article    The article to save.
**/
+ (void)asynchronouslySaveArticle:(MWKArticle *)article;

/**
 *  Cancel the asynchronous save for the @c article.
 *
 *  @param article    The article to cancel.
 **/
+ (void)cancelAsynchronousSaveForArticle:(MWKArticle *)article;

@end

NS_ASSUME_NONNULL_END
