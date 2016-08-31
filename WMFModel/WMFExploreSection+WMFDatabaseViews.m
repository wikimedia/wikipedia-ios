
#import "WMFExploreSection+WMFDatabaseViews.h"
#import "YapDatabase+WMFExtensions.h"

NSString *const WMFFeedSectionsSortedByDateView = @"WMFFeedSectionsSortedByDateView";

@implementation WMFExploreSection (WMFDatabaseViews)


+ (void)registerViewsInDatabase:(YapDatabase*)database{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        YapDatabaseViewGrouping *grouping = [self wmf_feedSectionGroupingSingleGroup];
        YapDatabaseViewSorting *sorting = [self wmf_feedSectionsComparisonSorted];
        YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting];
        [database wmf_registerView:databaseView withName:WMFFeedSectionsSortedByDateView];
    });
    
    
}
+ (YapDatabaseViewGrouping *)wmf_feedSectionGroupingSingleGroup{
    return [YapDatabaseViewGrouping withObjectBlock:^NSString *_Nullable(YapDatabaseReadTransaction *_Nonnull transaction, NSString *_Nonnull collection, NSString *_Nonnull key, WMFExploreSection *_Nonnull object) {
        if (![collection isEqualToString:[WMFExploreSection databaseCollectionName]]) {
            return nil;
        }else{
            return @"";
        }
    }];
}

+ (YapDatabaseViewSorting *)wmf_feedSectionsComparisonSorted{
    return [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction *_Nonnull transaction, NSString *_Nonnull group, NSString *_Nonnull collection1, NSString *_Nonnull key1, WMFExploreSection *_Nonnull object1, NSString *_Nonnull collection2, NSString *_Nonnull key2, WMFExploreSection *_Nonnull object2) {
        return [object1 compare:object2];
    }];
}


@end
