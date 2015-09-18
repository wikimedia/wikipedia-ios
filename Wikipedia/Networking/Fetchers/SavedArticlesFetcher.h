
#import "FetcherBase.h"

@class MWKArticle,
       MWKSavedPageList,
       MWKDataStore,
       WMFArticleFetcher,
       SavedArticlesFetcher;

@protocol SavedArticlesFetcherDelegate <FetchFinishedDelegate>

- (void)savedArticlesFetcher:(SavedArticlesFetcher*)savedArticlesFetcher
             didFetchArticle:(MWKArticle*)article
                    progress:(CGFloat)progress
                       error:(NSError*)error;

@end

@interface SavedArticlesFetcher : FetcherBase

+ (SavedArticlesFetcher*)sharedInstance;
+ (void)                 setSharedInstance:(SavedArticlesFetcher*)fetcher;

@property (nonatomic, strong, readonly) MWKSavedPageList* savedPageList;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

- (instancetype)initWithArticleFetcher:(WMFArticleFetcher*)articleFetcher NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id<SavedArticlesFetcherDelegate> fetchFinishedDelegate;

- (void)fetchSavedPageList:(MWKSavedPageList*)savedPageList;

- (void)getProgress:(WMFProgressHandler)progressBlock;

- (void)cancelFetch;

@end
