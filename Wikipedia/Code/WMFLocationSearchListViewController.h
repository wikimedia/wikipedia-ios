
#import "WMFArticleListTableViewController.h"
#import "WMFNearbyTitleListDataSource.h"



@interface WMFLocationSearchListViewController : WMFArticleListTableViewController

@property (nonatomic, strong, readonly) MWKSite* site;

- (instancetype)initWithSearchSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;

@end
