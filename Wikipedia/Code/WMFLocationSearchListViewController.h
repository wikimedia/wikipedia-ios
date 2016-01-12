
#import "WMFArticleListTableViewController.h"
#import "WMFNearbyTitleListDataSource.h"

@interface WMFLocationSearchListViewController : WMFArticleListTableViewController

@property (nonatomic, strong) WMFNearbyTitleListDataSource* dataSource;

@end
