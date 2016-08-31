
@import UIKit;
#import "WMFAnalyticsLogging.h"

@class MWKDataStore;
@class WMFFeedDataStore;
@class WMFArticlePreviewDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedViewController : UICollectionViewController<WMFAnalyticsViewNameProviding>

@property (nonatomic, strong) MWKDataStore *userStore;
@property (nonatomic, strong) WMFFeedDataStore *feedStore;
@property (nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

@property (nonatomic, assign) BOOL canScrollToTop;

@end

NS_ASSUME_NONNULL_END
