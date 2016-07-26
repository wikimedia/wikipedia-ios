@import UIKit;

#import "WMFAnalyticsLogging.h"

@class MWKSite;
@class MWKDataStore;
@class MWKSavedPageList;
@class MWKHistoryList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController : UITableViewController<WMFAnalyticsViewNameProviding>

@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, assign) BOOL canScrollToTop;

- (void)showSettings;;

@end

NS_ASSUME_NONNULL_END