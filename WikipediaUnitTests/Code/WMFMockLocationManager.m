#import "WMFMockLocationManager.h"

@interface WMFMockLocationManager ()

@property (nonatomic, strong) CLLocation* mockLocation;
@property (nonatomic, strong) CLHeading* mockHeading;

@end

@implementation WMFMockLocationManager

- (CLLocation*)location {
    return self.mockLocation;
}

- (void)setLocation:(CLLocation*)location {
    self.mockLocation = location;
    [self.delegate nearbyController:self didUpdateLocation:self.location];
}

- (void)setHeading:(CLHeading*)heading {
    self.mockHeading = heading;
    [self.delegate nearbyController:self didUpdateHeading:self.heading];
}

- (CLHeading*)heading {
    return self.mockHeading;
}

- (CLLocationManager*)locationManager {
    // return new manager w/o setting self as delegate
    return [[CLLocationManager alloc] init];
}

- (void)startMonitoringLocation {
    if (self.location) {
        [self.delegate nearbyController:self didUpdateLocation:self.location];
    }
    if (self.heading) {
        [self.delegate nearbyController:self didUpdateHeading:self.heading];
    }
}

- (void)         locationManager:(CLLocationManager*)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
}

- (void)stopMonitoringLocation {
}

- (AnyPromise*)reverseGeocodeLocation:(CLLocation*)location {
    return [AnyPromise promiseWithValue:nil];
}

@end
