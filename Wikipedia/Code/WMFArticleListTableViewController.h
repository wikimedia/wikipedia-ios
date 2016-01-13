
#import <UIKit/UIKit.h>
#import "WMFTitleListDataSource.h"
#import "WMFArticleSelectionDelegate.h"
#import "WMFAnalyticsLogging.h"

@class SSBaseDataSource, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleListTableViewController : UITableViewController<WMFAnalyticsLogging>

@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong, nullable) SSBaseDataSource<WMFTitleListDataSource>* dataSource;

/**
 *  Optional delegate which will is informed of selection.
 *
 *  If left @c nil, falls back to pushing an article container using its @c navigationController.
 */
@property (nonatomic, weak, nullable) id<WMFArticleSelectionDelegate> delegate;

@end


@interface WMFArticleListTableViewController (WMFSubclasses)

- (MWKHistoryDiscoveryMethod)discoveryMethod;
- (NSString*)                analyticsName;

- (WMFEmptyViewType)emptyViewType;

- (BOOL)     showsDeleteAllButton;
- (NSString*)deleteAllConfirmationText;
- (NSString*)deleteText;
- (NSString*)deleteCancelText;

@end

NS_ASSUME_NONNULL_END