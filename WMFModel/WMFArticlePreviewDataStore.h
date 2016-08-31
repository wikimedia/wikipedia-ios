#import "WMFBaseDataStore.h"

@class WMFArticlePreview, MWKSearchResult;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePreviewDataStore : WMFBaseDataStore

- (nullable WMFArticlePreview *)itemForURL:(NSURL *)url;

- (void)enumerateItemsWithBlock:(void (^)(WMFArticlePreview *_Nonnull item, BOOL *stop))block;

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithSearchResult:(MWKSearchResult*)searchResult;


@end

NS_ASSUME_NONNULL_END
