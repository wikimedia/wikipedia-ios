//
//  CLLocation+WMFComparison.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/29/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "CLLocation+WMFComparison.h"

@implementation CLLocation (WMFComparison)

- (BOOL)wmf_isEqual:(CLLocation *)rhs {
    if (self == rhs) {
        return YES;
    } else if (![rhs isKindOfClass:[CLLocation class]]) {
        return NO;
    } else {
        return [self distanceFromLocation:rhs] == 0 && self.horizontalAccuracy == rhs.horizontalAccuracy && self.verticalAccuracy == rhs.verticalAccuracy && [self.timestamp isEqualToDate:rhs.timestamp] && self.speed == rhs.speed && self.course == rhs.course;
    }
}

@end

@implementation CLPlacemark (WMFComparison)

- (BOOL)wmf_isEqual:(CLPlacemark *)rhs {
    if (self == rhs) {
        return YES;
    } else if (![rhs isKindOfClass:[CLPlacemark class]]) {
        return NO;
    } else {
        return WMF_RHS_PROP_EQUAL(location, wmf_isEqual:) && WMF_RHS_PROP_EQUAL(name, isEqualToString:) && WMF_RHS_PROP_EQUAL(addressDictionary, isEqualToDictionary:) && WMF_RHS_PROP_EQUAL(ISOcountryCode, isEqualToString:) && WMF_RHS_PROP_EQUAL(country, isEqualToString:) && WMF_RHS_PROP_EQUAL(postalCode, isEqualToString:) && WMF_RHS_PROP_EQUAL(administrativeArea, isEqualToString:) && WMF_RHS_PROP_EQUAL(subAdministrativeArea, isEqualToString:) && WMF_RHS_PROP_EQUAL(locality, isEqualToString:) && WMF_RHS_PROP_EQUAL(subLocality, isEqualToString:) && WMF_RHS_PROP_EQUAL(thoroughfare, isEqualToString:) && WMF_RHS_PROP_EQUAL(subLocality, isEqualToString:) && WMF_RHS_PROP_EQUAL(region, isEqual:) && WMF_RHS_PROP_EQUAL(timeZone, isEqualToTimeZone:) && WMF_RHS_PROP_EQUAL(inlandWater, isEqualToString:) && WMF_RHS_PROP_EQUAL(ocean, isEqualToString:) && WMF_RHS_PROP_EQUAL(areasOfInterest, isEqualToArray:);
    }
}

@end
