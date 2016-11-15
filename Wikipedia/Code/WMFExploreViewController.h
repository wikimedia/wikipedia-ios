@import UIKit;
#import "WMFAnalyticsLogging.h"
#import "WMFContentSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController : UICollectionViewController <WMFAnalyticsViewNameProviding, WMFAnalyticsContextProviding>

@property (nonatomic, strong, nullable) NSArray<id<WMFContentSource>> *contentSources;

@property (nonatomic, assign) BOOL canScrollToTop;

-(UIButton *) titleButton;

- (void)showSettings;

- (NSUInteger)numberOfSectionsInExploreFeed;

- (void)presentMoreViewControllerForGroup:(WMFContentGroup *)group animated:(BOOL)animated;

- (void)showInTheNewsForStory:(WMFFeedNewsStory *)story date:(nullable NSDate *)date animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
