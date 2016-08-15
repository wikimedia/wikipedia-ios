#import "WMFArticleListTableViewController.h"
#import "WMFSearchDataSource.h"

@interface WMFSearchResultsTableViewController : WMFArticleListTableViewController

@property(nonatomic, strong) WMFSearchDataSource *dataSource;

@end
