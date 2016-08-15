#import "WMFArticleListTableViewController.h"
#import "WMFRelatedTitleListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFRelatedTitleViewController : WMFArticleListTableViewController

@property (nonatomic, strong) WMFRelatedTitleListDataSource* dataSource;

@end

NS_ASSUME_NONNULL_END