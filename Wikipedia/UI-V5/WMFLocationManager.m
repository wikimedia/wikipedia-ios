
#import "WMFLocationManager.h"

#import "WMFLocationSearchFetcher.h"


NS_ASSUME_NONNULL_BEGIN

static CLLocationDistance WMFMinimumDistanceBeforeUpdatingLocation = 1.0; //meters before we update location

@interface WMFLocationManager ()<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong, readwrite) CLLocation* lastLocation;

@end

@implementation WMFLocationManager

- (void)dealloc {
    if (self.locationManager.delegate == self) {
        self.locationManager.delegate = nil;
    }
}

#pragma mark - Accessors

- (CLLocationManager*)locationManager {
    if (!_locationManager) {
        _locationManager                = [[CLLocationManager alloc] init];
        _locationManager.delegate       = self;
        _locationManager.activityType   = CLActivityTypeFitness;
        _locationManager.distanceFilter = WMFMinimumDistanceBeforeUpdatingLocation;
    }

    return _locationManager;
}

- (CLHeading* __nullable)lastHeading {
    return self.locationManager.heading;
}

#pragma mark - Public

- (void)startMonitoringLocation {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

    if (status == kCLAuthorizationStatusDenied ||
        status == kCLAuthorizationStatusRestricted) {
        //Updates not possible
        return;
    }

    if (status == kCLAuthorizationStatusNotDetermined && [self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        //Need authorization
        [self.locationManager requestWhenInUseAuthorization];

        return;
    }

    [self startLocationUpdates];
    [self startHeadingUpdates];
}

- (void)stopMonitoringLocation {
    [self stopLocationUpdates];
    [self stopHeadingUpdates];
}

#pragma mark - Location Updates

- (void)startLocationUpdates {
    [self.locationManager startUpdatingLocation];
}

- (void)startHeadingUpdates {
    [self.locationManager startUpdatingHeading];
}

- (void)stopLocationUpdates {
    [self.locationManager stopUpdatingLocation];
}

- (void)stopHeadingUpdates {
    [self.locationManager stopUpdatingHeading];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self startMonitoringLocation];
}

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations {
    if (locations.count == 0) {
        return;
    }

    CLLocation* currentLocation = [locations lastObject];

    self.lastLocation = currentLocation;
    [self.delegate nearbyController:self didUpdateLocation:currentLocation];
}

- (void)locationManager:(CLLocationManager*)manager didUpdateHeading:(CLHeading*)newHeading {
    [self.delegate nearbyController:self didUpdateHeading:newHeading];
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error {
    [self.delegate nearbyController:self didReceiveError:error];
}

@end

NS_ASSUME_NONNULL_END
