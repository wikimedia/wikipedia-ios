@import UIKit;
#import "WMFAnalyticsLogging.h"
#import "WMFContentSource.h"

@class MWKDataStore;
@class WMFContentGroupDataStore;
@class WMFArticlePreviewDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController : UICollectionViewController <WMFAnalyticsViewNameProviding, WMFAnalyticsContextProviding>

@property (nonatomic, strong) NSArray<id<WMFContentSource>> *contentSources;

@property (nonatomic, strong) MWKDataStore *userStore;
@property (nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

@property (nonatomic, assign) BOOL canScrollToTop;

- (void)showSettings;

- (NSUInteger)numberOfSectionsInExploreFeed;

- (void)presentMoreViewControllerForGroup:(WMFContentGroup *)group animated:(BOOL)animated;

- (void)updateFeedWithLatestDatabaseContent;

@end

NS_ASSUME_NONNULL_END
