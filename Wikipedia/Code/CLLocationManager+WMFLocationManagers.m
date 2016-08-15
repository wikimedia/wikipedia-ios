//
//  CLLocationManager+WMFLocationManagers.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/26/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "CLLocationManager+WMFLocationManagers.h"

@implementation CLLocationManager (WMFLocationManagers)

+ (instancetype)wmf_coarseLocationManager {
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    locationManager.activityType = CLActivityTypeFitness;
    locationManager.distanceFilter = 10;
    return locationManager;
}

+ (instancetype)wmf_fineLocationManager {
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.activityType = CLActivityTypeFitness;
    locationManager.distanceFilter = 1;
    return locationManager;
}

@end
