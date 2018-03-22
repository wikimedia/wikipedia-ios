@import WMF.FetcherBase;

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface NSError (SavedArticlesFetcherErrors)

/**
 *  @return Generic error used to indicate one or more images failed to download for the article or its gallery.
 */
+ (instancetype)wmf_savedPageImageDownloadError;

@end

@interface SavedArticlesFetcher : FetcherBase

@property (nonatomic, strong, readonly) NSNumber *fetchesInProcessCount;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
