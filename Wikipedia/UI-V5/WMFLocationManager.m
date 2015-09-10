
#import "WMFLocationManager.h"

#import "WMFLocationSearchFetcher.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationManager ()<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong, readwrite) CLLocation* lastLocation;

@end

@implementation WMFLocationManager

- (void)dealloc {
    self.locationManager.delegate = nil;
    [self stopMonitoringLocation];
}

#pragma mark - Accessors

- (CLLocationManager*)locationManager {
    if (!_locationManager) {
        _locationManager              = [[CLLocationManager alloc] init];
        _locationManager.delegate     = self;
        _locationManager.activityType = CLActivityTypeFitness;
        /*
           Update location every 1 meter. This is separate from how often we update the titles that are near a given
           location. See WMFNearbyViewModel.
         */
        _locationManager.distanceFilter = 1;
    }

    return _locationManager;
}

- (CLHeading* __nullable)lastHeading {
    return self.locationManager.heading;
}

- (CLLocation* __nullable)lastLocation {
    return self.locationManager.location;
}

#pragma mark - Permissions

+ (BOOL)isAuthorized {
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse;
}

- (BOOL)requestAuthorizationIfNeeded {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined
        && [self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
        return YES;
    }
    return NO;
}

#pragma mark - Location Monitoring

- (void)restartLocationMonitoring {
    [self stopMonitoringLocation];
    [self startMonitoringLocation];
}

- (void)startMonitoringLocation {
    if (![[self class] isAuthorized]) {
        [self requestAuthorizationIfNeeded];
        return;
    }

    NSParameterAssert([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse);

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

    [self.delegate nearbyController:self didUpdateLocation:manager.location];
}

- (void)locationManager:(CLLocationManager*)manager didUpdateHeading:(CLHeading*)newHeading {
    [self.delegate nearbyController:self didUpdateHeading:newHeading];
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error {
    [self.delegate nearbyController:self didReceiveError:error];
}

@end

NS_ASSUME_NONNULL_END
