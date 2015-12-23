
#import <Foundation/Foundation.h>
@import CoreLocation;

@class WMFLocationSearchResults;
@protocol WMFLocationManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WMFLocationManager : NSObject

@property (nonatomic, weak, nullable) id<WMFLocationManagerDelegate> delegate;

@property (nonatomic, strong, readonly) CLLocation* location;

@property (nonatomic, strong, readonly) CLHeading* heading;

- (void)startMonitoringLocation;
- (void)stopMonitoringLocation;
- (void)restartLocationMonitoring;

+ (BOOL)isAuthorized;

+ (BOOL)isDeniedOrDisabled;

@end


@protocol WMFLocationManagerDelegate <NSObject>

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location;

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading;

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error;

@optional

- (void)nearbyController:(WMFLocationManager*)controller didChangeEnabledState:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END