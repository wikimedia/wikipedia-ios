#import <WMF/CLLocationManager+WMFLocationManagers.h>

@implementation CLLocationManager (WMFLocationManagers)

+ (instancetype)wmf_fineLocationManager {
    NSAssert([NSThread isMainThread], @"Location managers must be created on the main thread");
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.activityType = CLActivityTypeFitness;
    locationManager.distanceFilter = 1;
    return locationManager;
}

+ (instancetype)wmf_coarseLocationManager {
    NSAssert([NSThread isMainThread], @"Location managers must be created on the main thread");
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    locationManager.activityType = CLActivityTypeFitness;
    locationManager.distanceFilter = 1000;
    return locationManager;
}

@end
