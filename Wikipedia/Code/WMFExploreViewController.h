@import UIKit;
#import "WMFAnalyticsLogging.h"
#import "WMFContentSource.h"

@class MWKDataStore;

extern const NSInteger WMFExploreFeedMaximumNumberOfDays;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController : UICollectionViewController <WMFAnalyticsViewNameProviding, WMFAnalyticsContextProviding>

@property (nonatomic, strong) MWKDataStore *userStore;

@property (nonatomic, assign) BOOL canScrollToTop;

- (UIButton *)titleButton;

- (NSUInteger)numberOfSectionsInExploreFeed;

- (void)presentMoreViewControllerForGroup:(WMFContentGroup *)group animated:(BOOL)animated;

- (void)showInTheNewsForStory:(WMFFeedNewsStory *)story date:(nullable NSDate *)date animated:(BOOL)animated;

- (void)updateFeedSourcesUserInititated:(BOOL)wasUserInitiated;

@end

NS_ASSUME_NONNULL_END
