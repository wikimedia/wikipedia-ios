#import <Foundation/Foundation.h>

@import CoreLocation;

/**
 *  Object which provides a dynamic bearing to a specific location.
 *
 *  Provided by @c WMFCompassViewModel, which updates instances of this class as the user's heading changes.
 */
@interface WMFSearchResultBearingProvider : NSObject

@property (nonatomic, assign) CLLocationDegrees bearingToLocation;

@end
