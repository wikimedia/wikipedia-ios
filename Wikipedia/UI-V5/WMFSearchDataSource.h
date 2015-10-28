
#import <SSDataSources/SSDataSources.h>
#import "WMFTitleListDataSource.h"

@class WMFSearchResults;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchDataSource : SSArrayDataSource<WMFTitleListDataSource>

@property (nonatomic, strong, readonly) MWKSite* searchSite;
@property (nonatomic, strong, readonly) WMFSearchResults* searchResults;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPageList;

- (nonnull instancetype)initWithSearchSite:(MWKSite*)site searchResults:(WMFSearchResults*)searchResults savedPages:(MWKSavedPageList*)savedPages;

@end

NS_ASSUME_NONNULL_END