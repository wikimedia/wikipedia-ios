//
//  CLLocation+WMFApproximateEquality.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "CLLocation+WMFApproximateEquality.h"

@implementation CLLocation (WMFApproximateEquality)

- (BOOL)wmf_hasSameCoordinatesAsLocation:(CLLocation*)location {
    if (!location) {
        return NO;
    }
    return self.coordinate.latitude == location.coordinate.latitude
           && self.coordinate.longitude == location.coordinate.longitude;
}

- (BOOL)wmf_isVeryCloseToLocation:(CLLocation*)location {
    return [self distanceFromLocation:location] <= 1;
}

@end
