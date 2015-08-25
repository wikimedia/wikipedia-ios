
#import "MWKSearchResult.h"
@import CoreLocation;

@interface MWKLocationSearchResult : MWKSearchResult<MTLJSONSerializing>

@property (nonatomic, strong, readonly) CLLocation* location;

@property (nonatomic, assign, readonly) CLLocationDistance distanceFromQueryCoordinates;

@end
