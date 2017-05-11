@import UIKit;
#import "WMFContentSource.h"

@class MWKDataStore;

extern const NSInteger WMFExploreFeedMaximumNumberOfDays;

NS_ASSUME_NONNULL_BEGIN


@protocol WMFExploreCollectionViewControllerDelegate<NSObject>

- (void)exploreCollectionViewDidScroll:(UIScrollView *)scrollView;

@end


@interface WMFExploreCollectionViewController : UICollectionViewController <WMFAnalyticsViewNameProviding, WMFAnalyticsContextProviding>

@property (nonatomic, strong) MWKDataStore *userStore;

@property (nonatomic, weak) id<WMFExploreCollectionViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL canScrollToTop;

- (UIButton *)titleButton;

- (NSUInteger)numberOfSectionsInExploreFeed;

- (void)presentMoreViewControllerForGroup:(WMFContentGroup *)group animated:(BOOL)animated;

- (void)showInTheNewsForStory:(WMFFeedNewsStory *)story date:(nullable NSDate *)date animated:(BOOL)animated;

- (void)updateFeedSourcesUserInitiated:(BOOL)wasUserInitiated;

@end

NS_ASSUME_NONNULL_END
