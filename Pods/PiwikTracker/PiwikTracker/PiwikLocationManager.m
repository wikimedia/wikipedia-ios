//
//  PiwikLocationManager.m
//  PiwikTracker
//
//  Created by Mattias Levin on 10/13/13.
//  Copyright (c) 2013 Mattias Levin. All rights reserved.
//

#import "PiwikLocationManager.h"


@interface PiwikLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) BOOL startMonitoringOnNextLocationRequest;
@property (nonatomic) BOOL isMonitorLocationChanges;

@end


@implementation PiwikLocationManager


- (id)init {
  self = [super init];
  if (self) {
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    
  }
  return self;
}


- (void)startMonitoringLocationChanges {
  
  if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
      [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
    // Not allowed to monitor location changes, do nothing
    return;
  }
  
  // If the app already have permission to track user location start monitoring. Otherwise wait untill the first location is requested
  // Do this to avoid asking for permission directly when the app starts
  // This will allow the app to to ask for permission at a controlled point in the application flow
  if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
    [self _startMonitoringLocationChanges];
  } else {
    self.startMonitoringOnNextLocationRequest = YES;
  }
  
}

- (void)_startMonitoringLocationChanges {
  
#if TARGET_OS_IPHONE
  
  // Workaround
  // Staring iOS8 you must explicitly ask for user authorization
  // Please note that the info.plist must contain the NSLocationWhenInUseUsageDescription key
  if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
    [self.locationManager requestWhenInUseAuthorization];
  }
  
  // Use significant change location service for iOS
  if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
    [self.locationManager startMonitoringSignificantLocationChanges];
    self.isMonitorLocationChanges = YES;
  }
  
#else
  
  if ([CLLocationManager locationServicesEnabled]) {
    // User standard service for OSX
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    self.locationManager.distanceFilter = 500; // meters
    [self.locationManager startUpdatingLocation];

    self.isMonitorLocationChanges = YES;
  }
  
#endif
  
}


- (void)stopMonitoringLocationChanges {
  self.isMonitorLocationChanges = NO;

#if TARGET_OS_IPHONE
  
  // Use significant change location service for iOS
  [self.locationManager stopMonitoringSignificantLocationChanges];
  
#else
  
  // User standard service for OSX  
  [self.locationManager stopUpdatingLocation];
  
#endif
  
}


- (CLLocation*)location {
  
  if (self.startMonitoringOnNextLocationRequest && !self.isMonitorLocationChanges) {
    [self _startMonitoringLocationChanges];
  }
  
  // Will return nil if the location monitoring has not been started
  return self.locationManager.location;
  
}


#pragma mark - core location delegate methods

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations {
  // Do nothing
}


- (void)locationManager:(CLLocationManager*)manager monitoringDidFailForRegion:(CLRegion*)region withError:(NSError*)error {
  // Do nothing
}


@end