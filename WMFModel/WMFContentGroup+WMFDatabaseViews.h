#import "WMFContentGroup+WMFDatabaseStorable.h"
#import "WMFDatabaseViewable.h"

#pragma mark - Registered View Names

extern NSString *const WMFContentGroupsSortedByDateView;

@interface WMFContentGroup (WMFDatabaseViews) <WMFDatabaseViewable>

+ (YapDatabaseViewGrouping *)wmf_contentGroupingSingleGroup;

+ (YapDatabaseViewSorting *)wmf_contentGroupsComparisonSorted;

@end
