//
//  NSString+WMFDistance.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/10/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSString+WMFDistance.h"

@implementation NSString (WMFDistance)

+ (NSString *)wmf_localizedStringForDistance:(CLLocationDistance)distance {
    return [self wmf_localizedStringForDistance:distance
                                 useMetricUnits:[[[NSLocale currentLocale]
                                                    objectForKey:(__bridge NSString *)kCFLocaleUsesMetricSystem] boolValue]];
}

+ (NSString *)wmf_localizedStringForDistance:(CLLocationDistance)distance useMetricUnits:(BOOL)useMetricUnits {
    // Make nearby use feet for meters according to locale.
    // stringWithFormat float decimal places: http://stackoverflow.com/a/6531587
    if (useMetricUnits) {
        if (distance > (999.0f / 10.0f)) {
            // Show in km if over 0.1 km.
            NSNumber *displayDistance = @(distance / 1000.0f);
            NSString *distanceIntString = [NSString stringWithFormat:@"%.2f", displayDistance.floatValue];
            return [MWLocalizedString(@"nearby-distance-label-km", nil)
                stringByReplacingOccurrencesOfString:@"$1"
                                          withString:distanceIntString];
        } else {
            // Show in meters if under 0.1 km.
            NSString *distanceIntString = [NSString stringWithFormat:@"%.f", distance];
            return [MWLocalizedString(@"nearby-distance-label-meters", nil)
                stringByReplacingOccurrencesOfString:@"$1"
                                          withString:distanceIntString];
        }
    } else {
        // Meters to feet.
        distance = distance * 3.28084f;

        if (distance > (5279.0f / 10.0f)) {
            // Show in miles if over 0.1 miles.
            NSNumber *displayDistance = @(distance / 5280.0f);
            NSString *distanceIntString = [NSString stringWithFormat:@"%.2f", displayDistance.floatValue];
            return [MWLocalizedString(@"nearby-distance-label-miles", nil)
                stringByReplacingOccurrencesOfString:@"$1"
                                          withString:distanceIntString];
        } else {
            // Show in feet if under 0.1 miles.
            NSString *distanceIntString = [NSString stringWithFormat:@"%.f", distance];
            return [MWLocalizedString(@"nearby-distance-label-feet", nil)
                stringByReplacingOccurrencesOfString:@"$1"
                                          withString:distanceIntString];
        }
    }
}

@end
