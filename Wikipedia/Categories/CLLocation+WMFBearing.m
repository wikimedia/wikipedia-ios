//
//  CLLocation+WMFBearing.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "CLLocation+WMFBearing.h"

@implementation CLLocation (WMFBearing)

- (CLLocationDegrees)wmf_bearingToLocation:(CLLocation*)destination {
    double dy = destination.coordinate.longitude - self.coordinate.longitude;
    double y  = sin(dy) * cos(destination.coordinate.latitude);
    double x  = cos(self.coordinate.latitude) * sin(destination.coordinate.latitude) - sin(self.coordinate.latitude) * cos(destination.coordinate.latitude) * cos(dy);
    return atan2(y, x);
}

- (CLLocationDegrees)wmf_bearingToLocation:(CLLocation*)location
                         forCurrentHeading:(CLHeading*)currentHeading {
    return [self wmf_bearingToLocation:location] - currentHeading.trueHeading;
}

@end
