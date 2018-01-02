#import "WMFViewController.h"

@class WMFContentGroup;
@class MWKDataStore;
@protocol WMFExploreViewControllerDelegate;

extern const NSInteger WMFExploreFeedMaximumNumberOfDays;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController : WMFViewController <WMFAnalyticsViewNameProviding, WMFAnalyticsContextProviding, WMFThemeable>

@property (nonatomic, strong, readonly) UICollectionView *collectionView;

@property (nonatomic, strong, readonly) WMFColumnarCollectionViewLayout *collectionViewLayout;

@property (nonatomic, strong) MWKDataStore *userStore;

@property (nonatomic, assign) BOOL canScrollToTop;

- (UIButton *)titleButton;

- (NSUInteger)numberOfSectionsInExploreFeed;

- (void)updateFeedSourcesUserInitiated:(BOOL)wasUserInitiated completion:(nonnull dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
