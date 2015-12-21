
#import <Foundation/Foundation.h>

@class MWKTitle;
@class MWKDataStore;
@class MWKArticle;
@class MWKArticlePreview;

NS_ASSUME_NONNULL_BEGIN

/**
 *  @see fetchLatestVersionOfTitleIfNeeded:progress:
 */
extern NSString* const WMFArticleFetcherErrorCachedFallbackArticleKey;

/* Temporary base class to hold common response serialization logic.
 * This can be removed when response serialization is moved into the
 * AFNetworking Serializers. See WMFArticleSerializer for more info.
 */
@interface WMFArticleBaseFetcher : NSObject

- (BOOL)isFetchingArticleForTitle:(MWKTitle*)pageTitle;
- (void)cancelFetchForPageTitle:(MWKTitle*)pageTitle;
- (void)cancelAllFetches;

@end

@interface WMFArticleFetcher : WMFArticleBaseFetcher

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

//Fullfilled promise returns MWKArticle
- (AnyPromise*)fetchArticleForPageTitle:(MWKTitle*)pageTitle progress:(WMFProgressHandler __nullable)progress;

/**
 *  Fetch the latest version of @c title, if the locally stored revision is not the latest.
 *
 *  @param title    The title to fetch.
 *  @param progress Block which will be invoked with download progress.
 *
 *  @return A promise which resolves to an article object. If there was a cached article, and an error was encountered,
 *          the error's @c userInfo will contain the cached article for the key @c WMFArticleFetcherErrorCachedFallbackArticleKey.
 */
- (AnyPromise*)fetchLatestVersionOfTitleIfNeeded:(MWKTitle*)title
                                        progress:(WMFProgressHandler __nullable)progress;


@property (nonatomic, assign, readonly) BOOL isFetching;

@end



@interface WMFArticlePreviewFetcher : WMFArticleBaseFetcher

//Fullfilled promise returns MWKArticlePreview
- (AnyPromise*)fetchArticlePreviewForPageTitle:(MWKTitle*)pageTitle progress:(WMFProgressHandler __nullable)progress;

@end



NS_ASSUME_NONNULL_END