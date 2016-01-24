
#import "WMFLocationSearchListViewController.h"

@interface WMFNearbyListViewController : WMFLocationSearchListViewController

- (instancetype)initWithSearchSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;

- (instancetype)initWithLocation:(CLLocation*)location searchSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore NS_UNAVAILABLE;

@end
