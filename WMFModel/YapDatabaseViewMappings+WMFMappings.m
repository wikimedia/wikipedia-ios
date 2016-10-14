#import "YapDatabaseViewMappings+WMFMappings.h"

@implementation YapDatabaseViewMappings (WMFMappings)

+ (YapDatabaseViewMappings *)wmf_ungroupedMappingsWithView:(NSString *)viewName {
    return [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *_Nonnull group, YapDatabaseReadTransaction *_Nonnull transaction) {
        return YES;
    }
        sortBlock:^NSComparisonResult(NSString *_Nonnull group1, NSString *_Nonnull group2, YapDatabaseReadTransaction *_Nonnull transaction) {
            return NSOrderedAscending;
        }
        view:viewName];
}

+ (YapDatabaseViewMappings *)wmf_groupsSortedAlphabeticallyMappingsWithViewName:(NSString *)viewName {
    return [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *_Nonnull group, YapDatabaseReadTransaction *_Nonnull transaction) {
        return YES;
    }
        sortBlock:^NSComparisonResult(NSString *_Nonnull group1, NSString *_Nonnull group2, YapDatabaseReadTransaction *_Nonnull transaction) {
            return [group1 localizedCaseInsensitiveCompare:group2];
        }
        view:viewName];
}

+ (YapDatabaseViewMappings *)wmf_groupsAsTimeIntervalsSortedDescendingMappingsWithView:(NSString *)viewName {
    return [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *_Nonnull group, YapDatabaseReadTransaction *_Nonnull transaction) {
        return YES;
    }
        sortBlock:^NSComparisonResult(NSString *_Nonnull group1, NSString *_Nonnull group2, YapDatabaseReadTransaction *_Nonnull transaction) {
            if ([group1 doubleValue] < [group2 doubleValue]) {
                return NSOrderedDescending;
            } else if ([group1 doubleValue] > [group2 doubleValue]) {
                return NSOrderedAscending;
            } else {
                return NSOrderedSame;
            }
        }
        view:viewName];
}
@end
