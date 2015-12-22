
#import "WMFLocationManager.h"
#import "WMFLocationSearchFetcher.h"

static DDLogLevel WMFLocationManagerLogLevel = DDLogLevelInfo;

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFLocationManagerLogLevel

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

- (NSString*)description {
    NSString* delegateDesc = [self.delegate description] ? : @"nil";
    return [NSString stringWithFormat:@"<%@ manager: %@ delegate: %@ is updating: %d>",
            [super description], _locationManager, delegateDesc, !self.locationUpdatesStopped];
}

#pragma mark - Permissions

+ (BOOL)isAuthorized {
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse;
}

- (BOOL)requestAuthorizationIfNeeded {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        DDLogVerbose(@"%@ is requesting authorization to access location when in use.", self);
        [self.locationManager requestWhenInUseAuthorization];
        return YES;
    }
    DDLogVerbose(@"%@ is skipping authorization request because status is %d.", self, status);
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

    DDLogVerbose(@"%@ will start location & heading updates.", self);

    self.locationUpdatesStopped = NO;
    [self startLocationUpdates];
    [self startHeadingUpdates];
}

- (void)stopMonitoringLocation {
    DDLogVerbose(@"%@ will stop location & heading updates.", self);
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
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            DDLogVerbose(@"Ignoring not determined status call, should have already requested authorization.");
            break;
        }

        case kCLAuthorizationStatusDenied: {
            WMF_TECH_DEBT_TODO(inform delegate that access was denied)
            break;
        }

        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            DDLogVerbose(@"%@ was granted access to location when in use, attempting to monitor location.", self);
            [self startMonitoringLocation];
            break;
        }

        default: {
            DDLogError(@"%@ was called with unexpected authorization status: %d", self, status);
            NSAssert(NO, @"Unexpected location authorization status: %d", status);
            break;
        }
    }
}

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations {
    if (self.locationUpdatesStopped) {
        return;
    }
    if (locations.count == 0) {
        return;
    }
    DDLogVerbose(@"%@ updated location: %@", self, manager.location);
    [self.delegate nearbyController:self didUpdateLocation:manager.location];
}

- (void)locationManager:(CLLocationManager*)manager didUpdateHeading:(CLHeading*)newHeading {
    if (self.locationUpdatesStopped) {
        return;
    }
    DDLogVerbose(@"%@ updated heading to %@", self, newHeading);
    [self.delegate nearbyController:self didUpdateHeading:newHeading];
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error {
    if (self.locationUpdatesStopped) {
        DDLogVerbose(@"Suppressing error received after call to stop monitoring location: %@", error);
        return;
    }
    #if TARGET_IPHONE_SIMULATOR
    else if (error.domain == kCLErrorDomain && error.code == kCLErrorLocationUnknown) {
        DDLogVerbose(@"Suppressing unknown location error.");
        return;
    }
    #endif
    DDLogError(@"%@ encountered error: %@", self, error);
    [self.delegate nearbyController:self didReceiveError:error];
}

@end

NS_ASSUME_NONNULL_END
