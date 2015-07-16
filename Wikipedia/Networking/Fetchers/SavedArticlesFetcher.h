
#import "FetcherBase.h"

@class MWKArticle, MWKSavedPageList, AFHTTPRequestOperationManager, SavedArticlesFetcher, MWKDataStore;

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
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

@property (nonatomic, weak) id<SavedArticlesFetcherDelegate> fetchFinishedDelegate;

- (void)fetchSavedPageList:(MWKSavedPageList*)savedPageList;

- (void)getProgress:(WMFProgressHandler)progressBlock;

- (void)cancelFetch;

@end
