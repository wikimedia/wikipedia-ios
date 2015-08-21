
#import <Mantle/Mantle.h>
@import CoreLocation;

@interface MWKLocationSearchResult : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign, readonly) NSInteger articleID;

@property (nonatomic, copy, readonly) NSString* displayTitle;

@property (nonatomic, copy, readonly) NSString* wikidataDescription;

@property (nonatomic, copy, readonly) NSURL* thumbnailURL;

@property (nonatomic, strong, readonly) CLLocation* location;

@property (nonatomic, assign, readonly) CLLocationDistance distanceFromQueryCoordinates;

@end
