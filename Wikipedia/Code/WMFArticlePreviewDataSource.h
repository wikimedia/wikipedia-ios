#import <Foundation/Foundation.h>
#import "SSArrayDataSource.h"
#import "WMFTitleListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@class MWKSearchResult;
@class WMFArticlePreviewFetcher;
@class MWKSavedPageList;
@class MWKDataStore;

@interface WMFArticlePreviewDataSource : SSArrayDataSource <WMFTitleListDataSource>

@property (nonatomic, strong, readonly, nullable) NSArray<MWKSearchResult *> *previewResults;
@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

- (instancetype)initWithArticleURLs:(NSArray<NSURL *> *)articleURLs
                            siteURL:(NSURL *)siteURL
                          dataStore:(MWKDataStore *)dataStore
                            fetcher:(WMFArticlePreviewFetcher *)fetcher NS_DESIGNATED_INITIALIZER;

- (void)fetch;

@end

NS_ASSUME_NONNULL_END
