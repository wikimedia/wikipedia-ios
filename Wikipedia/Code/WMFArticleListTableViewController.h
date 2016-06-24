
#import <UIKit/UIKit.h>
#import "WMFTitleListDataSource.h"
#import "WMFAnalyticsLogging.h"

@class SSBaseDataSource, MWKDataStore, WMFArticleListTableViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFArticleListTableViewControllerDelegate <NSObject>

- (void)listViewController:(WMFArticleListTableViewController*)listController didSelectTitle:(MWKTitle*)title;

- (UIViewController*)listViewController:(WMFArticleListTableViewController*)listController viewControllerForPreviewingTitle:(MWKTitle*)title;

- (void)listViewController:(WMFArticleListTableViewController*)listController didCommitToPreviewedViewController:(UIViewController*)viewController;

@end


@interface WMFArticleListTableViewController : UITableViewController<WMFAnalyticsContextProviding>

@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong, nullable) SSBaseDataSource<WMFTitleListDataSource>* dataSource;

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

@end

NS_ASSUME_NONNULL_END