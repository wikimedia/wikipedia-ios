
#import <Foundation/Foundation.h>
@import CoreLocation;

@class WMFLocationSearchResults;
@protocol WMFLocationManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationManager : NSObject

@property (nonatomic, strong, readonly) CLLocationManager* locationManager;

@property (nonatomic, strong, readonly) CLLocation* location;

@property (nonatomic, strong, readonly) CLHeading* heading;

+ (instancetype)sharedFineLocationManager;

+ (instancetype)sharedCoarseLocationManager;

/**
 *  Use one of the above factory methods instead.
 *
 *  @see fineLocationManager
 *  @see coarseLocationManager
 */
- (instancetype)init NS_UNAVAILABLE;

+ (BOOL)isAuthorized;

+ (BOOL)isDeniedOrDisabled;

- (AnyPromise*)reverseGeocodeLocation:(CLLocation*)location;

- (void)addDelegate:(id<WMFLocationManagerDelegate>)delegate;
- (void)removeDelegate:(id<WMFLocationManagerDelegate>)delegate;

@end


@protocol WMFLocationManagerDelegate <NSObject>

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location;

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading;

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error;

@optional

- (void)nearbyController:(WMFLocationManager*)controller didChangeEnabledState:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END