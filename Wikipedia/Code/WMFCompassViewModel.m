//
//  WMFCompassViewModel.m
//  Wikipedia
//
//  Created by Corey Floyd on 1/22/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFCompassViewModel.h"
#import "CLLocation+WMFBearing.h"
#import "WMFSearchResultDistanceProvider.h"
#import "WMFSearchResultBearingProvider.h"

#import "WMFLocationManager.h"
#import "MWKLocationSearchResult.h"

@interface WMFCompassViewModel ()
<WMFLocationManagerDelegate>

@property (nonatomic, strong) WMFLocationManager* locationManager;

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

@end


@implementation WMFCompassViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.locationManager          = [WMFLocationManager sharedFineLocationManager];
    }
    return self;
}

- (void)dealloc {
    [self.locationManager removeDelegate:self];
}

#pragma mark - Updates

- (void)startUpdates {
    [self.locationManager addDelegate:self];
}

- (void)stopUpdates {
    [self.locationManager removeDelegate:self];
}

#pragma mark - Value Providers

- (WMFSearchResultDistanceProvider*)distanceProviderForResult:(MWKLocationSearchResult*)result {
    WMFSearchResultDistanceProvider* provider = [WMFSearchResultDistanceProvider new];
    [provider.KVOController
     observe:self
     keyPath:WMF_SAFE_KEYPATH(self, lastLocation)
     options:NSKeyValueObservingOptionInitial
       block:^(WMFSearchResultDistanceProvider* observer, WMFCompassViewModel* compassViewModel, NSDictionary* _) {
        observer.distanceToUser = [result.location distanceFromLocation:compassViewModel.lastLocation];
    }];
    return provider;
}

- (WMFSearchResultBearingProvider*)bearingProviderForResult:(MWKLocationSearchResult*)result {
    WMFSearchResultBearingProvider* provider = [WMFSearchResultBearingProvider new];
    [provider.KVOController
     observe:self
     keyPath:WMF_SAFE_KEYPATH(self, lastHeading)
     options:NSKeyValueObservingOptionInitial
       block:^(WMFSearchResultBearingProvider* observer, WMFCompassViewModel* compassViewModel, NSDictionary* _) {
        observer.bearingToLocation =
            [compassViewModel.lastLocation wmf_bearingToLocation:result.location
                                               forCurrentHeading:compassViewModel.lastHeading];
    }];
    return provider;
}

#pragma mark - WMFNearbyControllerDelegate

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location {
    self.lastLocation = location;
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
    self.lastHeading = heading;
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
    WMF_TECH_DEBT_TODO(implement compass error handling);
//    if ([WMFLocationManager isDeniedOrDisabled]) {
//        //TODO: anything we need to handle?
//    }
//    if (![error.domain isEqualToString:kCLErrorDomain] && error.code == kCLErrorLocationUnknown) {
//        //TODO: anything we need to handle?
//    }
//    // should we stop updates?
//    [self stopUpdates];
}

@end
