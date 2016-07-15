@import UIKit;

#import "WMFAnalyticsLogging.h"

@class MWKSite;
@class MWKDataStore;
@class MWKSavedPageList;
@class MWKHistoryList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController : UICollectionViewController<WMFAnalyticsViewNameProviding>

@property (nonatomic, strong) MWKDataStore* dataStore;

- (void)showSettings;
- (void)scrollToTop:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END