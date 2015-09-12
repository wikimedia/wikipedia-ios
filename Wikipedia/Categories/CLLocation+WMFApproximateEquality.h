//
//  CLLocation+WMFApproximateEquality.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (WMFApproximateEquality)

/**
 *  Check if two locations point to the same coordinate.
 *
 *  @param location Another location object.
 *
 *  @return @c YES if the two location objects have identical @c coordinate values, otherwise @c NO.
 */
- (BOOL)wmf_hasSameCoordinatesAsLocation:(CLLocation*)location;

/**
 *  Check if one location is roughly equivalent to another.
 *
 *  @param location Another location object.
 *
 *  @return @c YES if the two locations are close enough to be considered equivalent, otherwise @c NO.
 */
- (BOOL)wmf_isVeryCloseToLocation:(CLLocation*)location;

@end
