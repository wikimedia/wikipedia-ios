
#import "WMFArticleListDataSourceTableViewController.h"
#import "WMFNearbyTitleListDataSource.h"
@import CoreLocation;


@interface WMFLocationSearchListViewController : WMFArticleListDataSourceTableViewController

@property (nonatomic, strong, readonly) NSURL* searchSiteURL;
@property (nonatomic, strong) CLLocation* location;

- (instancetype)initWithLocation:(CLLocation*)location searchSiteURL:(NSURL*)url dataStore:(MWKDataStore*)dataStore;

- (instancetype)initWithSearchSiteURL:(NSURL*)url dataStore:(MWKDataStore*)dataStore;

@end
