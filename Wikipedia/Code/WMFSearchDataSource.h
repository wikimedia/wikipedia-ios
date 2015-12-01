
#import <SSDataSources/SSDataSources.h>
#import "WMFTitleListDataSource.h"

@class MWKSite, WMFSearchResults;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchDataSource : SSArrayDataSource<WMFTitleListDataSource>

@property (nonatomic, strong, readonly) MWKSite* searchSite;
@property (nonatomic, strong, readonly) WMFSearchResults* searchResults;

- (nonnull instancetype)initWithSearchSite:(MWKSite*)site searchResults:(WMFSearchResults*)searchResults;

@end

NS_ASSUME_NONNULL_END