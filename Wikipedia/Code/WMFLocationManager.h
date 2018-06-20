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
 *  Start monitoring location and heading updates.
 *
 *  @note
 *  This method is idempotent. To force new values to be sent, use @c restartLocationMonitoring.
 */
- (void)startMonitoringLocation;

/**
 *  Stop monitoring location and heading updates.
 */
- (void)stopMonitoringLocation;

/**
 *  Restart location monitoring, forcing the receiver to emit new location and heading values (if possible).
 */
- (void)restartLocationMonitoring;

+ (BOOL)isAuthorized;

+ (BOOL)isAuthorizationNotDetermined;
+ (BOOL)isAuthorizationDenied;
+ (BOOL)isAuthorizationRestricted;

- (void)reverseGeocodeLocation:(CLLocation *)location completion:(void (^)(CLPlacemark *placemark))completion
                       failure:(void (^)(NSError *error))failure;

@end

@protocol WMFLocationManagerDelegate <NSObject>

@optional

- (void)locationManager:(WMFLocationManager *)controller didUpdateLocation:(CLLocation *)location;

- (void)locationManager:(WMFLocationManager *)controller didUpdateHeading:(CLHeading *)heading;

- (void)locationManager:(WMFLocationManager *)controller didReceiveError:(NSError *)error;

- (void)locationManager:(WMFLocationManager *)controller didChangeEnabledState:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
