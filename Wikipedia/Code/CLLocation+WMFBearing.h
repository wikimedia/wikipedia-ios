#import <CoreLocation/CoreLocation.h>

@interface CLLocation (WMFBearing)

/**
 *  Calculate the bearing from the receiver to a given location, relative to the user's current heading.
 *
 *  @param destination      The target destination.
 *  @param currentHeading   The heading reported by a location manger.
 *
 *  @return The relative bearing in degrees adjusted for the current heading.
 *
 *  @see -wmf_bearingToLocation:
 */
- (CLLocationDegrees)wmf_bearingToLocation:(CLLocation *)destination forCurrentHeading:(CLHeading *)currentHeading;

/**
 *  Calculate the bearing from the receiver to a given location.
 *
 *  Uses a special formula which accommodates for the Earth's approximate shape.  Native port of JS function
 *  @c LatLon.prototype.bearingTo on http://www.movable-type.co.uk/scripts/latlong.html
 *
 *  @param destination         The target destination.
 *
 *  @return The relative bearing in degrees, where a positive value goes in the clockwise direction.
 */
- (CLLocationDegrees)wmf_bearingToLocation:(CLLocation *)destination;

@end
