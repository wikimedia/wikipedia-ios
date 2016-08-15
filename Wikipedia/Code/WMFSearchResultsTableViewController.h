
#import "WMFArticleListDataSourceTableViewController.h"
#import "WMFSearchDataSource.h"

@interface WMFSearchResultsTableViewController : WMFArticleListDataSourceTableViewController

@property (nonatomic, strong) WMFSearchDataSource* dataSource;

@end
