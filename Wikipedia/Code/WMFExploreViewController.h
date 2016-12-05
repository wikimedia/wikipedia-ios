@import UIKit;
#import "WMFAnalyticsLogging.h"
#import "WMFContentSource.h"

@class MWKDataStore;
@class WMFContentGroupDataStore;
@class WMFArticleDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController : UICollectionViewController <WMFAnalyticsViewNameProviding, WMFAnalyticsContextProviding>

@property (nonatomic, strong) NSArray<id<WMFContentSource>> *contentSources;

@property (nonatomic, strong) MWKDataStore *userStore;
@property (nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (nonatomic, strong) WMFArticleDataStore *previewStore;

@property (nonatomic, assign) BOOL canScrollToTop;

- (UIButton *)titleButton;

- (void)showSettings;

- (NSUInteger)numberOfSectionsInExploreFeed;

- (void)presentMoreViewControllerForGroup:(WMFContentGroup *)group animated:(BOOL)animated;

- (void)showInTheNewsForStory:(WMFFeedNewsStory *)story date:(nullable NSDate *)date animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
