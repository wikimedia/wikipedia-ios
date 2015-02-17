
#import "FetcherBase.h"

@class MWKArticle, MWKSavedPageList, AFHTTPRequestOperationManager;
@class SavedArticlesFetcher;

@protocol SavedArticlesFetcherDelegate <FetchFinishedDelegate>

- (void)savedArticlesFetcher: (SavedArticlesFetcher*)savedArticlesFetcher
             didFetchArticle: (MWKArticle*)article
           remainingArticles: (NSInteger)remaining
               totalArticles: (NSInteger)total
                      status: (FetchFinalStatus)status
                       error: (NSError *)error;

@end

@interface SavedArticlesFetcher : FetcherBase

+ (SavedArticlesFetcher*)sharedInstance;
+ (void)setSharedInstance:(SavedArticlesFetcher*)fetcher;

@property (strong, nonatomic, readonly) MWKSavedPageList *savedPageList;
@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

@property (nonatomic, weak) id <SavedArticlesFetcherDelegate> fetchFinishedDelegate;

- (instancetype)initAndFetchArticlesForSavedPageList: (MWKSavedPageList *)savedPageList
                                         inDataStore: (MWKDataStore *)dataStore
                                         withManager: (AFHTTPRequestOperationManager *)manager
                                  thenNotifyDelegate: (id <SavedArticlesFetcherDelegate>) delegate;

@end
