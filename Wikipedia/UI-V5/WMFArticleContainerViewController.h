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

@interface WMFArticleContainerViewController : UIViewController
    <WMFArticleContentController, WMFArticleListItemController, WMFAnalyticsLogging>

+ (instancetype)articleContainerViewControllerWithDataStore:(MWKDataStore*)dataStore
                                                recentPages:(MWKHistoryList*)recentPages
                                                 savedPages:(MWKSavedPageList*)savedPages;

@property (nonatomic, strong, readonly) WMFArticleViewController* articleViewController;

@end

NS_ASSUME_NONNULL_END
