
#import "FetcherBase.h"

@class MWKArticle,
       MWKSavedPageList,
       WMFArticleFetcher,
       SavedArticlesFetcher,
       WMFImageController;

NS_ASSUME_NONNULL_BEGIN

@protocol SavedArticlesFetcherDelegate <FetchFinishedDelegate>

- (void)savedArticlesFetcher:(SavedArticlesFetcher*)savedArticlesFetcher
               didFetchTitle:(MWKTitle*)title
                     article:(MWKArticle* __nullable)article
                    progress:(CGFloat)progress
                       error:(NSError* __nullable)error;

@end

@interface SavedArticlesFetcher : FetcherBase

@property (nonatomic, strong, readonly) MWKSavedPageList* savedPageList;

@property (nonatomic, weak, nullable) id<SavedArticlesFetcherDelegate> fetchFinishedDelegate;

- (instancetype)initWithSavedPageList:(MWKSavedPageList*)savedPageList;

- (void)getProgress:(WMFProgressHandler)progressBlock;

- (void)fetchAndObserveSavedPageList;

- (void)cancelFetch;

@end

NS_ASSUME_NONNULL_END
