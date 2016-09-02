#import <SSDataSources/SSDataSources.h>
#import "WMFTitleListDataSource.h"

@class MWKSearchResult;

@interface WMFMostReadListDataSource : SSArrayDataSource <WMFTitleListDataSource>

- (instancetype)initWithItems:(NSArray *)items NS_UNAVAILABLE;

- (instancetype)initWithPreviews:(NSArray<MWKSearchResult *> *)previews fromSiteURL:(NSURL *)siteURL;

@end
