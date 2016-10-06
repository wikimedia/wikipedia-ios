#import "WMFBaseDataStore.h"

@class WMFArticlePreview, MWKSearchResult, MWKLocationSearchResult, MWKArticle;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePreviewDataStore : WMFBaseDataStore

- (nullable WMFArticlePreview *)itemForURL:(NSURL *)url;

- (void)enumerateItemsWithBlock:(void (^)(WMFArticlePreview *_Nonnull item, BOOL *stop))block;

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithSearchResult:(MWKSearchResult*)searchResult;

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithLocationSearchResult:(MWKLocationSearchResult*)searchResult;

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithArticle:(MWKArticle*)article;

@end

NS_ASSUME_NONNULL_END
