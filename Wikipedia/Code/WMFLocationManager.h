
#import <Foundation/Foundation.h>
@import CoreLocation;

@class WMFLocationSearchResults;
@protocol WMFLocationManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationManager : NSObject

@property (nonatomic, strong, readonly) CLLocationManager* locationManager;

@property (nonatomic, weak, nullable) id<WMFLocationManagerDelegate> delegate;

@property (nonatomic, strong, readonly) CLLocation* location;

@property (nonatomic, strong, readonly) CLHeading* heading;

/**
 *  Whether or not the receiver is listening for updates to location & heading.
 *
 *  @note
 *  CLLocationmanager doesn't always immediately listen to the request for stopping location updates
 *  We use this to ignore events after a stop has been requested
 */
@property (nonatomic, assign, readonly, getter=isUpdating) BOOL updating;

- (void)startMonitoringLocation;
- (void)stopMonitoringLocation;
- (void)restartLocationMonitoring;

+ (BOOL)isAuthorized;

+ (BOOL)isDeniedOrDisabled;

- (AnyPromise*)reverseGeocodeLocation:(CLLocation*)location;

@end


@protocol WMFLocationManagerDelegate <NSObject>

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location;

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading;

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error;

@optional

- (void)nearbyController:(WMFLocationManager*)controller didChangeEnabledState:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END