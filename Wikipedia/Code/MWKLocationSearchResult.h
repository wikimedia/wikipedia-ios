#import <WMF/MWKSearchResult.h>
#import <CoreLocation/CoreLocation.h>

/**
 *  Response object model for search results which have geocoordinates.
 *
 *  @warning This object only supports deserialization <b>from</b> JSON, not serialization <b>to</b> JSON.
 */
@interface MWKLocationSearchResult : MWKSearchResult <MTLJSONSerializing>

/**
 *  Number of meters between the receiver and the coordinate parameters of the originating search.
 */
@property (nonatomic, assign, readonly) CLLocationDistance distanceFromQueryCoordinates;

@end
