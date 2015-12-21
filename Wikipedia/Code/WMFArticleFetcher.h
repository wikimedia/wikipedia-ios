
#import <Foundation/Foundation.h>

@class MWKTitle;
@class MWKDataStore;
@class MWKArticle;
@class MWKArticlePreview;

NS_ASSUME_NONNULL_BEGIN

/* Temporary base class to hold common response serialization logic.
 * This can be removed when response serialization is moved into the
 * AFNetworking Serializers. See WMFArticleSerializer for more info.
 */
@interface WMFArticleBaseFetcher : NSObject

- (BOOL)isFetchingArticleForTitle:(MWKTitle*)pageTitle;
- (void)cancelFetchForPageTitle:(MWKTitle*)pageTitle;
- (void)cancelAllFetches;

@end

extern NSString* const WMFArticleFetcherErrorDomain;

extern NSString* const WMFArticleFetcherErrorCachedFallbackArticleKey;

@interface WMFArticleFetcher : WMFArticleBaseFetcher

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

//Fullfilled promise returns MWKArticle
- (AnyPromise*)fetchArticleForPageTitle:(MWKTitle*)pageTitle progress:(WMFProgressHandler __nullable)progress;

- (AnyPromise*)fetchLatestVersionOfTitleIfNeeded:(MWKTitle*)title
                                        progress:(WMFProgressHandler __nullable)progress;


@property (nonatomic, assign, readonly) BOOL isFetching;

@end



@interface WMFArticlePreviewFetcher : WMFArticleBaseFetcher

//Fullfilled promise returns MWKArticlePreview
- (AnyPromise*)fetchArticlePreviewForPageTitle:(MWKTitle*)pageTitle progress:(WMFProgressHandler __nullable)progress;

@end



NS_ASSUME_NONNULL_END