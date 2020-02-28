@import CoreLocation;

@class WMFLocationSearchResults;
@protocol WMFLocationManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationManager : NSObject

@property (nonatomic, strong, readonly) CLLocationManager *locationManager;

@property (nonatomic, weak, nullable) id<WMFLocationManagerDelegate> delegate;

@property (nonatomic, strong, readonly, nullable) CLLocation *location;

@property (nonatomic, strong, readonly, nullable) CLHeading *heading;

@property (nonatomic, readonly, getter=isUpdating) BOOL updating;

+ (instancetype)fineLocationManager;

+ (instancetype)coarseLocationManager;

/**
 *  Use one of the above factory methods instead.
 *
 *  @see fineLocationManager
 *  @see coarseLocationManager
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Start monitoring location and heading updates. This method is idempotent.
 *
 */
- (void)startMonitoringLocation;

/**
 *  Stop monitoring location and heading updates.
 */
- (void)stopMonitoringLocation;

- (BOOL)isAuthorized;
- (BOOL)isAuthorizationNotDetermined;
- (BOOL)isAuthorizationDenied;
- (BOOL)isAuthorizationRestricted;

@end

@protocol WMFLocationManagerDelegate <NSObject>

@optional

- (void)locationManager:(WMFLocationManager *)controller didUpdateLocation:(CLLocation *)location;

- (void)locationManager:(WMFLocationManager *)controller didUpdateHeading:(CLHeading *)heading;

- (void)locationManager:(WMFLocationManager *)controller didReceiveError:(NSError *)error;

- (void)locationManager:(WMFLocationManager *)controller didChangeEnabledState:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
