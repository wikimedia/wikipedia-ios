#import "WMFMockLocationManager.h"

@interface WMFMockLocationManager ()

@property (nonatomic, strong) CLLocation *mockLocation;
@property (nonatomic, strong) CLHeading *mockHeading;

@end

@implementation WMFMockLocationManager

- (CLLocation *)location {
    return self.mockLocation;
}

- (void)setLocation:(CLLocation *)location {
    self.mockLocation = location;
    [self.delegate locationManager:self didUpdateLocation:self.location];
}

- (void)setHeading:(CLHeading *)heading {
    self.mockHeading = heading;
    [self.delegate locationManager:self didUpdateHeading:self.heading];
}

- (CLHeading *)heading {
    return self.mockHeading;
}

- (CLLocationManager *)locationManager {
    // return new manager w/o setting self as delegate
    return [[CLLocationManager alloc] init];
}

- (void)startMonitoringLocation {
    if (self.location) {
        [self.delegate locationManager:self didUpdateLocation:self.location];
    }
    if (self.heading) {
        [self.delegate locationManager:self didUpdateHeading:self.heading];
    }
}

- (void)locationManager:(CLLocationManager *)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
}

- (void)stopMonitoringLocation {
}

- (void)reverseGeocodeLocation:(CLLocation *)location completion:(nonnull void (^)(CLPlacemark *_Nonnull))completion failure:(nonnull void (^)(NSError *_Nonnull))failure {
    failure([NSError errorWithDomain:@"" code:0 userInfo:nil]);
}

@end
