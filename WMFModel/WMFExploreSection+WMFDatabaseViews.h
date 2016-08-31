
#import "WMFExploreSection+WMFDatabaseStorable.h"
#import "WMFDatabaseViewable.h"

#pragma mark - Registered View Names

extern NSString *const WMFFeedSectionsSortedByDateView;

@interface WMFExploreSection (WMFDatabaseViews)<WMFDatabaseViewable>

+ (YapDatabaseViewGrouping *)wmf_feedSectionGroupingSingleGroup;

+ (YapDatabaseViewSorting *)wmf_feedSectionsComparisonSorted;


@end
