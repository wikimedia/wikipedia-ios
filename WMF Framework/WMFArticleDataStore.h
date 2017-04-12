@class MWKSearchResult, MWKLocationSearchResult, MWKArticle, WMFFeedArticlePreview, WMFArticle;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleDataStore : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

- (nullable WMFArticle *)itemForURL:(NSURL *)url inManagedObjectContext:(NSManagedObjectContext *)moc;

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithSearchResult:(MWKSearchResult *)searchResult inManagedObjectContext:(NSManagedObjectContext *)moc;

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithLocationSearchResult:(MWKLocationSearchResult *)searchResult inManagedObjectContext:(NSManagedObjectContext *)moc;

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithArticle:(MWKArticle *)article inManagedObjectContext:(NSManagedObjectContext *)moc;

- (nullable WMFArticle *)addPreviewWithURL:(NSURL *)url updatedWithFeedPreview:(WMFFeedArticlePreview *)feedPreview pageViews:(nullable NSDictionary<NSDate *, NSNumber *> *)pageViews inManagedObjectContext:(NSManagedObjectContext *)moc;

- (void)updatePreview:(WMFArticle *)preview withSearchResult:(MWKSearchResult *)searchResult inManagedObjectContext:(NSManagedObjectContext *)moc;

@end

NS_ASSUME_NONNULL_END
