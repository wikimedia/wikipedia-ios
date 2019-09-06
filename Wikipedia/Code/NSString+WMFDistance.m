#import <WMF/NSString+WMFDistance.h>
#import <WMF/WMFLocalization.h>

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
            return [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"nearby-distance-label-km", nil, nil, @"%1$@ km", @"Label for showing distance in kilometers to nearby geotagged articles.\n\nParameters:\n* %1$@ - the number of kilometers. (The iOS app doesn't support pluralization syntax yet.)\n{{Related|Wikipedia-ios-nearby-distance-label}}"), distanceIntString];
        } else {
            // Show in meters if under 0.1 km.
            NSString *distanceIntString = [NSString stringWithFormat:@"%.f", distance];
            return [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"nearby-distance-label-meters", nil, nil, @"%1$@ m", @"Label for showing distance in meters to nearby geotagged articles.\n\nParameters:\n* %1$@ - the number of meters. (The iOS app doesn't support pluralization syntax yet.)\n{{Related|Wikipedia-ios-nearby-distance-label}}"), distanceIntString];
        }
    } else {
        // Meters to feet.
        distance = distance * 3.28084f;

        if (distance > (5279.0f / 10.0f)) {
            // Show in miles if over 0.1 miles.
            NSNumber *displayDistance = @(distance / 5280.0f);
            NSString *distanceIntString = [NSString stringWithFormat:@"%.2f", displayDistance.floatValue];
            return [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"nearby-distance-label-miles", nil, nil, @"%1$@ miles", @"Label for showing distance in miles to nearby geotagged articles.\n\nParamaeters:\n* %1$@ - the number of miles. (The iOS app doesn't support pluralization syntax yet.)\n{{Related|Wikipedia-ios-nearby-distance-label}} {{Identical|Mile}}"), distanceIntString];
        } else {
            // Show in feet if under 0.1 miles.
            NSString *distanceIntString = [NSString stringWithFormat:@"%.f", distance];
            return [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"nearby-distance-label-feet", nil, nil, @"%1$@ feet", @"Label for showing distance in feet to nearby geotagged articles.\n\nParameters:\n* %1$@ - the number of feet. (The iOS app doesn't support pluralization syntax yet.)\n{{Related|Wikipedia-ios-nearby-distance-label}}"), distanceIntString];
        }
    }
}

@end
