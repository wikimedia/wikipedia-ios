
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

// TODO: move to separate file in article container folder
@interface WMFSelfSizingArticleListTableViewController : WMFArticleListTableViewController

@end

NS_ASSUME_NONNULL_END