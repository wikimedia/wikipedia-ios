@import UIKit;

#import "WMFAnalyticsLogging.h"

@class MWKDataStore;
@class MWKSavedPageList;
@class MWKHistoryList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController : UICollectionViewController<WMFAnalyticsViewNameProviding>

@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, assign) BOOL canScrollToTop;

- (void)showSettings;

- (NSUInteger)numberOfSectionsInExploreFeed;

@end

NS_ASSUME_NONNULL_END