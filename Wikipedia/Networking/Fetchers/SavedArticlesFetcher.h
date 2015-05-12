
#import "FetcherBase.h"

@class MWKArticle, MWKSavedPageList, AFHTTPRequestOperationManager;
@class SavedArticlesFetcher;

typedef void (^ WMFSavedArticlesFetcherProgress)(CGFloat progress);

@protocol SavedArticlesFetcherDelegate <FetchFinishedDelegate>

- (void)savedArticlesFetcher:(SavedArticlesFetcher*)savedArticlesFetcher
             didFetchArticle:(MWKArticle*)article
                    progress:(CGFloat)progress
                      status:(FetchFinalStatus)status
                       error:(NSError*)error;

@end

@interface SavedArticlesFetcher : FetcherBase

+ (SavedArticlesFetcher*)sharedInstance;
+ (void)                 setSharedInstance:(SavedArticlesFetcher*)fetcher;

@property (nonatomic, strong, readonly) MWKSavedPageList* savedPageList;
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

- (void)getProgress:(WMFSavedArticlesFetcherProgress)progressBlock;

@property (nonatomic, weak) id<SavedArticlesFetcherDelegate> fetchFinishedDelegate;

- (instancetype)initAndFetchArticlesForSavedPageList:(MWKSavedPageList*)savedPageList
                                         inDataStore:(MWKDataStore*)dataStore
                                         withManager:(AFHTTPRequestOperationManager*)manager
                                  thenNotifyDelegate:(id <SavedArticlesFetcherDelegate>)delegate;

@end
