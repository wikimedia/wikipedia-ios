
#import "MWKSearchResult.h"
@import CoreLocation;

/**
 *  Response object model for search results which have geocoordinates.
 *
 *  @warning This object only supports deserialization <b>from</b> JSON, not serialization <b>to</b> JSON.
 */
@interface MWKLocationSearchResult : MWKSearchResult<MTLJSONSerializing>

/**
 *  Location serialized from the first set of coordinates in the response.
 */
@property (nonatomic, strong, readonly) CLLocation* location;

/**
 *  Number of meters between the receiver and the coordinate parameters of the originating search.
 */
@property (nonatomic, assign, readonly) CLLocationDistance distanceFromQueryCoordinates;

/**
 *  @name Automatically Updating Properties
 *
 *  These properties are set automatically by @c WMFNearbyViewModel in response to location & heading updates.
 *
 *  @see -[WMFNearbyViewModel autoUpdateResultAtIndex:]
 */

/**
 *  Distance in meters from the user's current location.
 */
@property (nonatomic, assign) CLLocationDistance distanceFromUser;

/**
 *  Bearing in degrees relative to the user's current true heading.
 *
 *  This value is relative in that 0 means directly in front of the user, 180 is behind, and so on.
 */
@property (nonatomic, assign) CLLocationDegrees bearingToLocation;

@end
