
#import "WMFLocationSearchListViewController.h"

@interface WMFNearbyListViewController : WMFLocationSearchListViewController

- (instancetype)initWithSearchSiteURL:(NSURL*)siteURL dataStore:(MWKDataStore*)dataStore;

- (instancetype)initWithLocation:(CLLocation*)location searchSiteURL:(NSURL*)siteURL dataStore:(MWKDataStore*)dataStore NS_UNAVAILABLE;

@end
