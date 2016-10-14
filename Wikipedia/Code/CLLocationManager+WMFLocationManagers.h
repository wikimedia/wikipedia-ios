#import <CoreLocation/CoreLocation.h>

@interface CLLocationManager (WMFLocationManagers)

/**
 *  Used to update views that display live location & bearing to the user.
 *
 *  @return A location manager configured for finer-grained updates.
 */
+ (instancetype)wmf_fineLocationManager;

/**
 *  Used to update business logic whenever location changes 10 meters.
 *
 *  @return A location manager configured for coarse-grained updates.
 */
+ (instancetype)wmf_coarseLocationManager;

@end
