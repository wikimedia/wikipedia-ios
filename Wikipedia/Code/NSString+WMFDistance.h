@import CoreLocation;

@interface NSString (WMFDistance)

/**
 *  Create a human-readable string from the given distance, localized to @c locale.
 *
 *  @param distance       The distance to stringify.
 *  @param useMetricUnits Whether to use feet/miles or meters/kilometers.
 *
 *  @return The distance as a localized string.
 */
+ (NSString *)wmf_localizedStringForDistance:(CLLocationDistance)distance useMetricUnits:(BOOL)useMetricUnits;

/**
 *  Convenience for @c +wmf_localizedStringForDistance:useMetricUnits: that determines whether to use metric units
 *  based on the current locale.
 *
 *  @param distance The distance to stringify.
 *
 *  @return The distaince as a localized string.
 */
+ (NSString *)wmf_localizedStringForDistance:(CLLocationDistance)distance;

@end
