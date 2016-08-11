
#import <UIKit/UIKit.h>
#import "UIViewController+WMFEmptyView.h"
#import "WMFAnalyticsLogging.h"

@class MWKDataStore;
@class WMFArticleListTableViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFArticleListTableViewControllerDelegate <NSObject>

- (void)listViewController:(WMFArticleListTableViewController*)listController didSelectArticleURL:(NSURL*)url;

- (UIViewController*)listViewController:(WMFArticleListTableViewController*)listController viewControllerForPreviewingArticleURL:(NSURL*)url;

- (void)listViewController:(WMFArticleListTableViewController*)listController didCommitToPreviewedViewController:(UIViewController*)viewController;

@end

@interface WMFArticleListTableViewController : UITableViewController<WMFAnalyticsContextProviding>

@property (nonatomic, strong) MWKDataStore* dataStore;

/**
 *  Optional delegate which will is informed of selection.
 *
 *  If left @c nil, falls back to pushing an article container using its @c navigationController.
 */
@property (nonatomic, weak, nullable) id<WMFArticleListTableViewControllerDelegate> delegate;

@end


@interface WMFArticleListTableViewController (WMFSubclasses)

- (NSString*)analyticsContext;

- (WMFEmptyViewType)emptyViewType;

- (BOOL)     showsDeleteAllButton;
- (NSString*)deleteButtonText;
- (NSString*)deleteAllConfirmationText;
- (NSString*)deleteText;
- (NSString*)deleteCancelText;

- (void)deleteAll;

- (NSInteger)numberOfItems;

- (NSURL*)urlAtIndexPath:(NSIndexPath*)indexPath;

- (void)updateEmptyAndDeleteState;



@end


NS_ASSUME_NONNULL_END