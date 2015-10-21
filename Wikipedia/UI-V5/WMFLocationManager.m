
#import "WMFLocationManager.h"

#import "WMFLocationSearchFetcher.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationManager ()<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong, nullable) id orientationNotificationToken;

/**
 *  CLLocationmanager doesn't always immediately listen to the request for stopping location updates
 *  We use this to ignore events after a stop has been requested
 */
@property (nonatomic, assign) BOOL locationUpdatesStopped;

@end

@implementation WMFLocationManager

- (void)dealloc {
    self.locationManager.delegate = nil;
    [self stopMonitoringLocation];
}

#pragma mark - Accessors

- (CLHeading*)heading {
    return self.locationManager.heading;
}

- (CLLocation*)location {
    return self.locationManager.location;
}

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

    self.locationUpdatesStopped = NO;
    [self startLocationUpdates];
    [self startHeadingUpdates];
}

- (void)stopMonitoringLocation {
    self.locationUpdatesStopped = YES;
    [self stopLocationUpdates];
    [self stopHeadingUpdates];
}

#pragma mark - Location Updates

- (void)startLocationUpdates {
    [self.locationManager startUpdatingLocation];
}

- (void)startHeadingUpdates {
    if (![[UIDevice currentDevice] isGeneratingDeviceOrientationNotifications]) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    @weakify(self);
    self.orientationNotificationToken =
        [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification* note) {
        @strongify(self);
        [self updateHeadingOrientation];
    }];
    [self updateHeadingOrientation];
    [self.locationManager startUpdatingHeading];
}

- (void)updateHeadingOrientation {
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationFaceDown:
            self.locationManager.headingOrientation = CLDeviceOrientationFaceDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.locationManager.headingOrientation = CLDeviceOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.locationManager.headingOrientation = CLDeviceOrientationLandscapeRight;
            break;
        case UIDeviceOrientationFaceUp:
            self.locationManager.headingOrientation = CLDeviceOrientationFaceUp;
            break;
        case UIDeviceOrientationPortrait:
            self.locationManager.headingOrientation = CLDeviceOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            self.locationManager.headingOrientation = CLDeviceOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationUnknown:
        default:
            self.locationManager.headingOrientation = CLDeviceOrientationUnknown;
            break;
    }
}

- (void)stopLocationUpdates {
    [self.locationManager stopUpdatingLocation];
}

- (void)stopHeadingUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self.orientationNotificationToken];
    self.orientationNotificationToken = nil;
    [self.locationManager stopUpdatingHeading];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self startMonitoringLocation];
}

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations {
    if (self.locationUpdatesStopped) {
        return;
    }
    if (locations.count == 0) {
        return;
    }
    [self.delegate nearbyController:self didUpdateLocation:manager.location];
}

- (void)locationManager:(CLLocationManager*)manager didUpdateHeading:(CLHeading*)newHeading {
    if (self.locationUpdatesStopped) {
        return;
    }
    [self.delegate nearbyController:self didUpdateHeading:newHeading];
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error {
    if (self.locationUpdatesStopped) {
        return;
    }
    [self.delegate nearbyController:self didReceiveError:error];
}

@end

NS_ASSUME_NONNULL_END
