@import UIKit;

#import "WMFAnalyticsLogging.h"

@class MWKDataStore;
@class MWKSavedPageList;
@class MWKHistoryList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController : UITableViewController<WMFAnalyticsViewNameProviding>

@property (nonatomic, strong) MWKDataStore* dataStore;

- (void)showSettings;
- (void)scrollToTop:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END