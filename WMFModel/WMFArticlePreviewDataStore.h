#import "WMFBaseDataStore.h"

@class WMFArticlePreview, MWKSearchResult, MWKLocationSearchResult, MWKArticle, WMFFeedArticlePreview;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePreviewDataStore : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

- (nullable WMFArticlePreview *)itemForURL:(NSURL *)url;

- (void)enumerateItemsWithBlock:(void (^)(WMFArticlePreview *_Nonnull item, BOOL *stop))block;

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithSearchResult:(MWKSearchResult *)searchResult;

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithLocationSearchResult:(MWKLocationSearchResult *)searchResult;

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithArticle:(MWKArticle *)article;

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithFeedPreview:(WMFFeedArticlePreview *)feedPreview pageViews:(nullable NSDictionary<NSDate *, NSNumber *> *)pageViews;

@end

NS_ASSUME_NONNULL_END
