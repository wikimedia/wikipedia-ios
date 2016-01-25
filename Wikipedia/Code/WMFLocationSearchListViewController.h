
#import "WMFArticleListTableViewController.h"
#import "WMFNearbyTitleListDataSource.h"
@import CoreLocation;


@interface WMFLocationSearchListViewController : WMFArticleListTableViewController

@property (nonatomic, strong, readonly) MWKSite* site;
@property (nonatomic, strong) CLLocation* location;

- (instancetype)initWithLocation:(CLLocation*)location searchSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;

- (instancetype)initWithSearchSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;

@end
