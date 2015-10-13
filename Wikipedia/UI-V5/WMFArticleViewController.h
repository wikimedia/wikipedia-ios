
#import <UIKit/UIKit.h>
#import "WMFArticleNavigationDelegate.h"
#import "WMFAnalyticsLogging.h"
#import "WMFArticleListItemController.h"

@class MWKDataStore;
@class MWKSavedPageList;
@class WMFArticleViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFArticleViewControllerDelegate <WMFArticleNavigationDelegate>

- (void)articleViewController:(WMFArticleViewController*)articleViewController didTapSectionWithFragment:(NSString*)fragment;

@end

@interface WMFArticleViewController : UITableViewController
    <WMFArticleListItemController, WMFAnalyticsLogging>

+ (instancetype)articleViewControllerWithDataStore:(MWKDataStore*)dataStore;

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;

@property (nonatomic, weak) id<WMFArticleViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
