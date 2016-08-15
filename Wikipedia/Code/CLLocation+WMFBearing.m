//
//  CLLocation+WMFBearing.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "CLLocation+WMFBearing.h"
#import "WMFGeometry.h"

@implementation CLLocation (WMFBearing)

- (CLLocationDegrees)wmf_bearingToLocation:(CLLocation *)destination {
    double const phiOrigin = DEGREES_TO_RADIANS(self.coordinate.latitude),
                 phiDest = DEGREES_TO_RADIANS(destination.coordinate.latitude),
                 deltaLambda = DEGREES_TO_RADIANS(destination.coordinate.longitude - self.coordinate.longitude),
                 y = sin(deltaLambda) * cos(phiDest),
                 x = cos(phiOrigin) * sin(phiDest) - sin(phiOrigin) * cos(phiDest) * cos(deltaLambda),
                 // bearing in radians in range [-180, 180]
        veBearingRadians = atan2(y, x);
    // convert to degrees and put in compass range [0, 360]
    return fmod(RADIANS_TO_DEGREES(veBearingRadians) + 360.0, 360.0);
}

- (CLLocationDegrees)wmf_bearingToLocation:(CLLocation *)location
                         forCurrentHeading:(CLHeading *)currentHeading {
    CLLocationDegrees bearing = [self wmf_bearingToLocation:location];

    // use true heading if available, otherwise fall back to magnetic heading
    if (currentHeading.trueHeading >= 0) {
        return bearing - currentHeading.trueHeading;
    } else {
        return bearing - currentHeading.magneticHeading;
    }
}

@end
