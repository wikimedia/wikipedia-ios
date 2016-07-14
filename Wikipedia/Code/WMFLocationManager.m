
#import "WMFLocationManager.h"
#import "WMFLocationSearchFetcher.h"
#import "CLLocationManager+WMFLocationManagers.h"

static DDLogLevel WMFLocationManagerLogLevel = DDLogLevelInfo;

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFLocationManagerLogLevel

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationManager ()<CLLocationManagerDelegate>

@property (nonatomic, strong, readwrite) CLLocationManager* locationManager;
@property (nonatomic, strong, nullable) id orientationNotificationToken;

/**
 *  @name Location Manager State
 *
 *  We need to keep track of these properties to ensure that the UI isn't emptied if the location manager is restarted,
 *  which will temporarily set its @c location and @c heading properties to @c nil.
 */

/**
 *  The last-known location reported by the @c locationManager.
 */
@property (nonatomic, strong, readwrite, nullable) CLLocation* lastLocation;

/**
 *  The last-known heading reported by the @c locationManager.
 */
@property (nonatomic, strong, readwrite, nullable) CLHeading* lastHeading;

/**
 *  Whether or not the receiver is listening for updates to location & heading.
 *
 *  @note
 *  CLLocationmanager doesn't always immediately listen to the request for stopping location updates
 *  We use this to ignore events after a stop has been requested
 */
@property (nonatomic, assign, readwrite, getter = isUpdating) BOOL updating;

/**
 *  Whether or not the receiver made the request for location authorization in order to begin updating location.
 */
@property (nonatomic, assign, readwrite, getter = isRequestingAuthorizationAndStart) BOOL requestingAuthorizationAndStart;

@property (nonatomic, assign, readwrite) CLAuthorizationStatus currentAuthorizationStatus;

- (instancetype)initWithLocationManager:(CLLocationManager*)locationManager NS_DESIGNATED_INITIALIZER;

@end

@implementation WMFLocationManager

+ (instancetype)fineLocationManager {
    return [[self alloc] initWithLocationManager:[CLLocationManager wmf_fineLocationManager]];
}

+ (instancetype)coarseLocationManager {
    return [[self alloc] initWithLocationManager:[CLLocationManager wmf_coarseLocationManager]];
}

- (instancetype)initWithLocationManager:(CLLocationManager*)locationManager {
    self = [super init];
    if (self) {
        self.currentAuthorizationStatus = [CLLocationManager authorizationStatus];
        self.locationManager     = locationManager;
        locationManager.delegate = self;
    }
    return self;
}

- (void)dealloc {
    self.locationManager.delegate = nil;
    [self stopMonitoringLocation];
}

#pragma mark - Accessors

- (CLHeading*)heading {
    return self.lastHeading;
}

- (CLLocation*)location {
    return self.lastLocation;
}

- (NSString*)description {
    NSString* delegateDesc = [self.delegate description] ? : @"nil";
    return [NSString stringWithFormat:@"<%@ manager: %@ delegate: %@ is updating: %d>",
            [super description], _locationManager, delegateDesc, self.isUpdating];
}

#pragma mark - Permissions

+ (BOOL)isAuthorized {
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse;
}

+ (BOOL)isDeniedOrDisabled {
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted;
}

- (BOOL)requestAuthorizationIfNeeded {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        NSParameterAssert([CLLocationManager locationServicesEnabled]);
        DDLogInfo(@"%@ is requesting authorization to access location when in use.", self);
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
    self.requestingAuthorizationAndStart = YES;
    if ([self requestAuthorizationIfNeeded] || [WMFLocationManager isDeniedOrDisabled] || self.isUpdating) {
        return;
    }
    self.requestingAuthorizationAndStart = NO;

    NSParameterAssert([WMFLocationManager isAuthorized]);

    self.updating = YES;
    DDLogInfo(@"%@ starting monitoring location & heading updates.", self);
    [self startLocationUpdates];
    [self startHeadingUpdates];
}

- (void)stopMonitoringLocation {
    if (self.isUpdating) {
        self.updating = NO;
        DDLogInfo(@"%@ stopping location & heading updates.", self);
        [self stopLocationUpdates];
        [self stopHeadingUpdates];
    }
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
                                                      usingBlock:^(NSNotification* _) {
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
    // Force location manager to re-emit the current heading which will take into account the current device orientation
    [self.locationManager stopUpdatingHeading];
    [self.locationManager startUpdatingHeading];
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
    //only continue if there's a change in authorization status
    if (self.currentAuthorizationStatus == status) {
        return;
    }
    self.currentAuthorizationStatus = status;
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted: {
            DDLogVerbose(@"Ignoring not determined status call, should have already requested authorization.");
            break;
        }

        case kCLAuthorizationStatusDenied: {
            if ([self.delegate respondsToSelector:@selector(nearbyController:didChangeEnabledState:)]) {
                DDLogInfo(@"Informing delegate about denied access to user's location.");
                [self.delegate nearbyController:self didChangeEnabledState:NO];
            }
            break;
        }

        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways: {
            DDLogInfo(@"%@ was granted access to location when in use, attempting to monitor location.", self);
            if ([self.delegate respondsToSelector:@selector(nearbyController:didChangeEnabledState:)]) {
                [self.delegate nearbyController:self didChangeEnabledState:YES];
            }
            if (self.isRequestingAuthorizationAndStart) { //only start if we requested as a part of a start
                [self startMonitoringLocation];
            }
            break;
        }
    }
}

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations {
    // ignore nil values to keep last known heading on the screen
    if (!self.isUpdating || !manager.location) {
        return;
    }
    self.lastLocation = manager.location;
    DDLogVerbose(@"%@ updated location: %@", self, self.lastLocation);
    [self.delegate nearbyController:self didUpdateLocation:self.lastLocation];
}

- (void)locationManager:(CLLocationManager*)manager didUpdateHeading:(CLHeading*)newHeading {
    // ignore nil or innaccurate values values to keep last known heading on the screen
    if (!self.isUpdating || !newHeading || newHeading.headingAccuracy <= 0) {
        return;
    }
    self.lastHeading = newHeading;
    DDLogVerbose(@"%@ updated heading to %@", self, self.lastHeading);
    [self.delegate nearbyController:self didUpdateHeading:self.lastHeading];
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error {
    if (!self.isUpdating) {
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

#pragma mark - Geocoding

- (AnyPromise*)reverseGeocodeLocation:(CLLocation*)location {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        [[[CLGeocoder alloc] init] reverseGeocodeLocation:location completionHandler:^(NSArray <CLPlacemark*>* _Nullable placemarks, NSError* _Nullable error) {
            if (error) {
                resolve(error);
            } else {
                resolve(placemarks.firstObject);
            }
        }];
    }];
}

@end

NS_ASSUME_NONNULL_END
