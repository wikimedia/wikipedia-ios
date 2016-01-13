
#import <Foundation/Foundation.h>
#import <SSDataSources/SSArrayDataSource.h>
#import "WMFTitleListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@class WMFRelatedSearchResults;
@class WMFRelatedSearchFetcher;
@class MWKSavedPageList;
@class MWKDataStore;
@class MWKTitle;

@interface WMFRelatedTitleListDataSource : SSArrayDataSource
    <WMFTitleListDataSource>

@property (nonatomic, strong, readonly, nullable) WMFRelatedSearchResults* relatedSearchResults;
@property (nonatomic, copy, readonly) MWKTitle* title;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPageList;

- (instancetype)initWithTitle:(MWKTitle*)title
                    dataStore:(MWKDataStore*)dataStore
                  resultLimit:(NSUInteger)resultLimit;

- (instancetype)initWithTitle:(MWKTitle*)title
                    dataStore:(MWKDataStore*)dataStore
                  resultLimit:(NSUInteger)resultLimit
                      fetcher:(WMFRelatedSearchFetcher*)fetcher NS_DESIGNATED_INITIALIZER;

- (AnyPromise*)fetch;

@end

NS_ASSUME_NONNULL_END
