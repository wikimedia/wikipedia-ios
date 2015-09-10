
#import "WMFSaveableTitleCollectionViewCell.h"
@import CoreLocation;

@class MWKLocationSearchResult;

@interface WMFHomeNearbyCell : WMFSaveableTitleCollectionViewCell

@property (copy, nonatomic) NSString* descriptionText;

@property (assign, nonatomic) CLLocationDistance distance;

- (void)setBearing:(CLLocationDegrees)bearing;

- (void)setCompassHidden:(BOOL)compassHidden;

- (void)setLocationSearchResult:(MWKLocationSearchResult*)locationSearchResult;

@end
