
#import "WMFSaveableTitleCollectionViewCell.h"
@import CoreLocation;

@class MWKLocationSearchResult;

@interface WMFNearbySearchResultCell : WMFSaveableTitleCollectionViewCell

/**
 *  Display the given search result.
 *
 *  Populates the receiver with data in the given result, in addition to binding to properties which are updated
 *  automatically (i.e. @c distanceFromUser and @c bearingToLocation).
 *
 *  @warning Use this instead of @c -setTitle:.
 *
 *  @param locationSearchResult The result whose data will be displayed in the receiver.
 */
- (void)setLocationSearchResult:(MWKLocationSearchResult*)locationSearchResult withTitle:(MWKTitle*)title;

@end
