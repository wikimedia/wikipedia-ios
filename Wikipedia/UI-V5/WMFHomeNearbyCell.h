
#import "WMFShadowCell.h"
@import CoreLocation;

@interface WMFHomeNearbyCell : WMFShadowCell

@property (copy, nonatomic) NSURL* imageURL;
@property (copy, nonatomic) NSString* titleText;
@property (copy, nonatomic) NSString* descriptionText;

@property (assign, nonatomic) CLLocationDistance distance;
@property (copy, nonatomic) NSNumber* headingAngle;

@end
