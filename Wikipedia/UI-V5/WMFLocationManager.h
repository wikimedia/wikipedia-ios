
#import <Foundation/Foundation.h>
@import CoreLocation;

@class WMFLocationSearchResults;
@protocol WMFNearbyControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationManager : NSObject

@property (nonatomic, assign, nullable) id<WMFNearbyControllerDelegate> delegate;

@property (nonatomic, strong, readonly, nullable) CLLocation* lastLocation;
@property (nonatomic, strong, readonly, nullable) CLHeading* lastHeading;

- (void)startMonitoringLocation;
- (void)stopMonitoringLocation;

@end


@protocol WMFNearbyControllerDelegate <NSObject>

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location;
- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading;

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error;

@end

NS_ASSUME_NONNULL_END