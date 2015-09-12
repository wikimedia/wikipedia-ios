
#import "WMFSaveableTitleCollectionViewCell.h"
@import CoreLocation;

@class MWKLocationSearchResult;
@class WMFSearchResultBearingProvider;
@class WMFSearchResultDistanceProvider;

@interface WMFNearbySearchResultCell : WMFSaveableTitleCollectionViewCell

- (void)setSearchResultDescription:(NSString*)searchResultDescription;

- (void)setDistanceProvider:(WMFSearchResultDistanceProvider*)distanceProvider;

- (void)setBearingProvider:(WMFSearchResultBearingProvider*)bearingProvider;

@end
