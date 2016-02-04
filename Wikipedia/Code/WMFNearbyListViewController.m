
#import "WMFNearbyListViewController.h"
#import "WMFLocationManager.h"
#import "Wikipedia-Swift.h"

@interface WMFNearbyListViewController ()<WMFLocationManagerDelegate>

@property (nonatomic, strong) WMFLocationManager* locationManager;

@end

@implementation WMFNearbyListViewController

- (instancetype)initWithSearchSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore {
    self = [super initWithSearchSite:site dataStore:dataStore];
    if (self) {
        [self.locationManager startMonitoringLocation];
    }
    return self;
}

- (WMFLocationManager*)locationManager {
    if (_locationManager == nil) {
        _locationManager          = [[WMFLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

#pragma mark - WMFLocationManagerDelegate

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location {
    self.location = location;
    [self.locationManager stopMonitoringLocation];
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
    [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
}

@end
