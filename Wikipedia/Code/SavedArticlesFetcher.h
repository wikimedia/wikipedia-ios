#import "FetcherBase.h"

@class MWKArticle,
    MWKSavedPageList,
    WMFArticleFetcher,
    SavedArticlesFetcher,
    WMFImageController,
    MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface NSError (SavedArticlesFetcherErrors)

/**
 *  @return Generic error used to indicate one or more images failed to download for the article or its gallery.
 */
+ (instancetype)wmf_savedPageImageDownloadError;

@end

@protocol SavedArticlesFetcherDelegate <FetchFinishedDelegate>

- (void)savedArticlesFetcher:(SavedArticlesFetcher *)savedArticlesFetcher
                 didFetchURL:(NSURL *)url
                     article:(MWKArticle *__nullable)article
                       error:(NSError *__nullable)error;

@end

@interface SavedArticlesFetcher : FetcherBase

@property (nonatomic, strong, readonly) MWKSavedPageList *savedPageList;

@property (nonatomic, weak, nullable) id<SavedArticlesFetcherDelegate> fetchFinishedDelegate;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore
                    savedPageList:(MWKSavedPageList *)savedPageList;

- (void)start;
- (void)stop;
- (void)fetchUncachedArticlesInSavedPages:(dispatch_block_t)completion;
- (void)cancelFetchForSavedPages;

@end

NS_ASSUME_NONNULL_END
