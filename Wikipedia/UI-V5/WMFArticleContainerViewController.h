@import UIKit;
#import "WMFArticleContentController.h"
#import "WMFArticleListItemController.h"
#import "WMFAnalyticsLogging.h"

@class WMFArticleViewController;
@class MWKDataStore;
@class MWKSavedPageList;
@class MWKArticle;
@class MWKHistoryList;

NS_ASSUME_NONNULL_BEGIN

/**
 *  View controller responsible for displaying article content.
 */
@interface WMFArticleContainerViewController : UIViewController
    <WMFArticleContentController, WMFArticleListItemController, WMFAnalyticsLogging>

// TEMP: will be deleted soon
@property (nonatomic, strong, readonly) WMFArticleViewController* articleViewController;

@end

NS_ASSUME_NONNULL_END
