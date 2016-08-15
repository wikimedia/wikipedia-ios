#import "WMFArticleListTableViewController.h"
#import "WMFNearbyTitleListDataSource.h"
@import CoreLocation;


@interface WMFLocationSearchListViewController : WMFArticleListTableViewController

@property (nonatomic, strong, readonly) NSURL* searchSiteURL;
@property (nonatomic, strong) CLLocation* location;

- (instancetype)initWithLocation:(CLLocation*)location searchSiteURL:(NSURL*)url dataStore:(MWKDataStore*)dataStore;

- (instancetype)initWithSearchSiteURL:(NSURL*)url dataStore:(MWKDataStore*)dataStore;

@end
