#import "WMFContentGroup+WMFDatabaseViews.h"
#import "YapDatabase+WMFExtensions.h"
#import "WMFContentGroup+WMFFeedContentDisplaying.h"

NSString *const WMFContentGroupsSortedByDateView = @"WMFContentGroupsSortedByDateView";

@implementation WMFContentGroup (WMFDatabaseViews)

+ (void)registerViewsInDatabase:(YapDatabase *)database {
    YapDatabaseViewGrouping *grouping = [self wmf_contentGroupingSingleGroup];
    YapDatabaseViewSorting *sorting = [self wmf_contentGroupsComparisonSorted];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:@"2"];
    [database wmf_registerView:databaseView withName:WMFContentGroupsSortedByDateView];
}
+ (YapDatabaseViewGrouping *)wmf_contentGroupingSingleGroup {
    return [YapDatabaseViewGrouping withObjectBlock:^NSString *_Nullable(YapDatabaseReadTransaction *_Nonnull transaction, NSString *_Nonnull collection, NSString *_Nonnull key, WMFContentGroup *_Nonnull object) {
        if (![collection isEqualToString:[WMFContentGroup databaseCollectionName]]) {
            return nil;
        } else {
            return @"";
        }
    }];
}

+ (YapDatabaseViewSorting *)wmf_contentGroupsComparisonSorted {
    return [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction *_Nonnull transaction, NSString *_Nonnull group, NSString *_Nonnull collection1, NSString *_Nonnull key1, WMFContentGroup *_Nonnull object1, NSString *_Nonnull collection2, NSString *_Nonnull key2, WMFContentGroup *_Nonnull object2) {
        return [object1 compare:object2];
    }];
}

@end
