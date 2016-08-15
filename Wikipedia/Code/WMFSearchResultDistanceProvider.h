#import <Foundation/Foundation.h>

@import CoreLocation;

/**
 *  Object which provides a dynamic distance to a specific location.
 *
 *  Provided by @c WMFCompassViewModel, which updates instances of this class as the user's location changes.
 */
@interface WMFSearchResultDistanceProvider : NSObject

@property(nonatomic, assign) CLLocationDistance distanceToUser;

@end
