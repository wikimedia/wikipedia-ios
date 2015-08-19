
#import <SSDataSources/SSDataSources.h>
@import CoreLocation;

@interface WMFHomeNearbyCell : SSBaseCollectionCell

@property (copy, nonatomic) NSURL* imageURL;
@property (copy, nonatomic) NSString* titleText;
@property (copy, nonatomic) NSString* descriptionText;

@property (assign, nonatomic) CLLocationDistance distance;
@property (copy, nonatomic) NSNumber* headingAngle;

@end
