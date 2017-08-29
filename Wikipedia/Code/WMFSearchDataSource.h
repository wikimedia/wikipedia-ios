#import "SSDataSources.h"
#import "WMFTitleListDataSource.h"

@class WMFSearchResults;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchDataSource : SSArrayDataSource <WMFTitleListDataSource>

@property (nonatomic, strong, readonly) NSURL *searchSiteURL;
@property (nonatomic, strong, readonly) WMFSearchResults *searchResults;

- (nonnull instancetype)initWithSearchSiteURL:(NSURL *)url searchResults:(WMFSearchResults *)searchResults;

@end

NS_ASSUME_NONNULL_END
