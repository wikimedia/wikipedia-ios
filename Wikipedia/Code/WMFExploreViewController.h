@import UIKit;

#import "WMFAnalyticsLogging.h"

@class MWKSite;
@class MWKDataStore;
@class MWKSavedPageList;
@class MWKHistoryList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController : UITableViewController<WMFAnalyticsViewNameProviding>

@property (nonatomic, strong) MWKSite* searchSite;
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

- (void)setSearchSite:(MWKSite* _Nonnull)searchSite dataStore:(MWKDataStore* _Nonnull)dataStore;

@end

NS_ASSUME_NONNULL_END