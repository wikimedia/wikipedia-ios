
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

- (void)savedArticlesFetcher:(SavedArticlesFetcher*)savedArticlesFetcher
                 didFetchURL:(NSURL*)url
                     article:(MWKArticle* __nullable)article
                    progress:(CGFloat)progress
                       error:(NSError* __nullable)error;

@end

@interface SavedArticlesFetcher : FetcherBase

@property (nonatomic, strong, readonly) MWKSavedPageList* savedPageList;

@property (nonatomic, weak, nullable) id<SavedArticlesFetcherDelegate> fetchFinishedDelegate;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore savedPageList:(MWKSavedPageList*)savedPageList;

- (void)getProgress:(WMFProgressHandler)progressBlock;

- (void)start;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
