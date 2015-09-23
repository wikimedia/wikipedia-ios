
#import "FetcherBase.h"

@class MWKArticle,
       MWKSavedPageList,
       MWKDataStore,
       WMFArticleFetcher,
       SavedArticlesFetcher;

@protocol SavedArticlesFetcherDelegate <FetchFinishedDelegate>

- (void)savedArticlesFetcher:(SavedArticlesFetcher*)savedArticlesFetcher
               didFetchTitle:(MWKTitle*)title
                     article:(MWKArticle*)article
                    progress:(CGFloat)progress
                       error:(NSError*)error;

@end

@interface SavedArticlesFetcher : FetcherBase

+ (SavedArticlesFetcher*)sharedInstance;
+ (void)                 setSharedInstance:(SavedArticlesFetcher*)fetcher;

@property (nonatomic, strong) MWKSavedPageList* savedPageList;

@property (nonatomic, weak) id<SavedArticlesFetcherDelegate> fetchFinishedDelegate;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

- (instancetype)initWithArticleFetcher:(WMFArticleFetcher*)articleFetcher NS_DESIGNATED_INITIALIZER;

- (void)getProgress:(WMFProgressHandler)progressBlock;

- (void)cancelFetch;

@end
