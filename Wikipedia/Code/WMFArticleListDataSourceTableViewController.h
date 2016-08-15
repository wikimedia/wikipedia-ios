
#import "WMFArticleListTableViewController.h"
#import "WMFTitleListDataSource.h"

@class SSBaseDataSource, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleListDataSourceTableViewController : WMFArticleListTableViewController

@property (nonatomic, strong, nullable) SSBaseDataSource<WMFTitleListDataSource>* dataSource;

@end



NS_ASSUME_NONNULL_END