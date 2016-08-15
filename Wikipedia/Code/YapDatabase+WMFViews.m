
#import "YapDatabase+WMFViews.h"
#import "YapDatabase+WMFExtensions.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import "NSDate+Utilities.h"

@implementation YapDatabase (WMFViews)

- (void)wmf_registerViews {
    YapDatabaseViewGrouping* grouping = [self wmf_historyGroupingSingleGroup];
    YapDatabaseViewSorting* sorting   = [self wmf_historySortedByDateDescending];
    YapDatabaseView* databaseView     = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting];
    [self wmf_registerView:databaseView withName:WMFHistorySortedByDateUngroupedView];

    grouping     = [self wmf_historyGroupingByDate];
    sorting      = [self wmf_historySortedByDateDescending];
    databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting];
    [self wmf_registerView:databaseView withName:WMFHistorySortedByDateGroupedByDateView];

    grouping     = [self wmf_savedGroupingSingleGroup];
    sorting      = [self wmf_savedSortedByDateDescending];
    databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting];
    [self wmf_registerView:databaseView withName:WMFSavedSortedByDateUngroupedView];

    grouping     = [self wmf_historyOrSavedGroupingSingleGroup];
    sorting      = [self wmf_historyOrSavedSortedByURL];
    databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:@"1"];
    [self wmf_registerView:databaseView withName:WMFHistoryOrSavedSortedByURLUngroupedView];

    grouping     = [self wmf_blackListGroupingSingleGroup];
    sorting      = [self wmf_historyOrSavedSortedByURL];
    databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting];
    [self wmf_registerView:databaseView withName:WMFBlackListSortedByURLUngroupedView];

    grouping     = [self wmf_notInHistorySavedOrBlackListGroupingSingleGroup];
    sorting      = [self wmf_historyOrSavedSortedByURL];
    databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting];
    [self wmf_registerView:databaseView withName:WMFNotInHistorySavedOrBlackListSortedByURLUngroupedView];

    YapDatabaseViewFiltering* filtering   = [self wmf_historyOrSavedSignificantlyViewedAndNotBlacklistedAndNotMainPageFilter];
    YapDatabaseFilteredView* filteredView =
        [[YapDatabaseFilteredView alloc] initWithParentViewName:WMFHistoryOrSavedSortedByURLUngroupedView filtering:filtering versionTag:@"3"];
    [self wmf_registerView:filteredView withName:WMFHistoryOrSavedSortedByURLUngroupedFilteredBySignificnatlyViewedAndNotBlacklistedAndNotMainPageView];
}

- (YapDatabaseViewGrouping*)wmf_historyGroupingSingleGroup {
    return [YapDatabaseViewGrouping withObjectBlock:^NSString* _Nullable (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull collection, NSString* _Nonnull key, MWKHistoryEntry* _Nonnull object) {
        if (![collection isEqualToString:[MWKHistoryEntry databaseCollectionName]]) {
            return nil;
        }
        if (object.dateViewed == nil) {
            return nil;
        }
        return @"";
    }];
}

- (YapDatabaseViewGrouping*)wmf_savedGroupingSingleGroup {
    return [YapDatabaseViewGrouping withObjectBlock:^NSString* _Nullable (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull collection, NSString* _Nonnull key, MWKHistoryEntry* _Nonnull object) {
        if (![collection isEqualToString:[MWKHistoryEntry databaseCollectionName]]) {
            return nil;
        }
        if (object.dateSaved == nil) {
            return nil;
        }
        return @"";
    }];
}

- (YapDatabaseViewGrouping*)wmf_historyOrSavedGroupingSingleGroup {
    return [YapDatabaseViewGrouping withObjectBlock:^NSString* _Nullable (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull collection, NSString* _Nonnull key, MWKHistoryEntry* _Nonnull object) {
        if (![collection isEqualToString:[MWKHistoryEntry databaseCollectionName]]) {
            return nil;
        }
        if (object.dateViewed == nil && object.dateSaved == nil) {
            return nil;
        }
        return @"";
    }];
}

- (YapDatabaseViewGrouping*)wmf_historyGroupingByDate {
    return [YapDatabaseViewGrouping withObjectBlock:^NSString* _Nullable (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull collection, NSString* _Nonnull key, MWKHistoryEntry* _Nonnull object) {
        if (![collection isEqualToString:[MWKHistoryEntry databaseCollectionName]]) {
            return nil;
        }
        if (object.dateViewed == nil) {
            return nil;
        }
        NSDate* date = [[object dateViewed] dateAtStartOfDay];
        return [NSString stringWithFormat:@"%f", [date timeIntervalSince1970]];
    }];
}

- (YapDatabaseViewGrouping*)wmf_blackListGroupingSingleGroup {
    return [YapDatabaseViewGrouping withObjectBlock:^NSString* _Nullable (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull collection, NSString* _Nonnull key, MWKHistoryEntry* _Nonnull object) {
        if (![collection isEqualToString:[MWKHistoryEntry databaseCollectionName]]) {
            return nil;
        }
        if (object.isBlackListed) {
            return @"";
        } else {
            return nil;
        }
    }];
}

- (YapDatabaseViewGrouping*)wmf_notInHistorySavedOrBlackListGroupingSingleGroup {
    return [YapDatabaseViewGrouping withObjectBlock:^NSString* _Nullable (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull collection, NSString* _Nonnull key, MWKHistoryEntry* _Nonnull object) {
        if (![collection isEqualToString:[MWKHistoryEntry databaseCollectionName]]) {
            return nil;
        }
        if (object.dateViewed == nil && object.dateSaved == nil && object.blackListed == NO) {
            return @"";
        } else {
            return nil;
        }
    }];
}

- (YapDatabaseViewSorting*)wmf_historySortedByDateDescending {
    return [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull group, NSString* _Nonnull collection1, NSString* _Nonnull key1, MWKHistoryEntry* _Nonnull object1, NSString* _Nonnull collection2, NSString* _Nonnull key2, MWKHistoryEntry* _Nonnull object2) {
        return -[object1.dateViewed compare:object2.dateViewed];
    }];
}

- (YapDatabaseViewSorting*)wmf_savedSortedByDateDescending {
    return [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull group, NSString* _Nonnull collection1, NSString* _Nonnull key1, MWKHistoryEntry* _Nonnull object1, NSString* _Nonnull collection2, NSString* _Nonnull key2, MWKHistoryEntry* _Nonnull object2) {
        return -[object1.dateSaved compare:object2.dateSaved];
    }];
}

- (YapDatabaseViewSorting*)wmf_historyOrSavedSortedByURL {
    return [YapDatabaseViewSorting withKeyBlock:^NSComparisonResult (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull group, NSString* _Nonnull collection1, NSString* _Nonnull key1, NSString* _Nonnull collection2, NSString* _Nonnull key2) {
        return [key1 compare:key2];
    }];
}

- (YapDatabaseViewFiltering*)wmf_historyOrSavedSignificantlyViewedAndNotBlacklistedAndNotMainPageFilter {
    return [YapDatabaseViewFiltering withObjectBlock:^BOOL (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull group, NSString* _Nonnull collection, NSString* _Nonnull key, MWKHistoryEntry* _Nonnull object) {
        if ([object isBlackListed] || [[object url] wmf_isMainPage]) {
            return NO;
        } else if (object.dateViewed != nil && [object titleWasSignificantlyViewed]) {
            return YES;
        } else if (object.dateSaved) {
            return YES;
        } else {
            return NO;
        }
    }];
}

- (YapDatabaseViewFiltering*)wmf_excludedKeysFilter:(NSArray<NSString*>*)keysToExclude {
    return [YapDatabaseViewFiltering withKeyBlock:^BOOL (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull group, NSString* _Nonnull collection, NSString* _Nonnull key) {
        return ![keysToExclude containsObject:key];
    }];
}

- (YapDatabaseViewFiltering*)wmf_objectWithKeyFilter:(NSString*)databaseKey {
    return [YapDatabaseViewFiltering withKeyBlock:^BOOL (YapDatabaseReadTransaction* _Nonnull transaction, NSString* _Nonnull group, NSString* _Nonnull collection, NSString* _Nonnull key) {
        return [databaseKey isEqualToString:key];
    }];
}

NSString* const WMFHistorySortedByDateGroupedByDateView                                                               = @"WMFHistorySortedByDateGroupedByDateView";
NSString* const WMFHistorySortedByDateUngroupedView                                                                   = @"WMFHistorySortedByDateUngroupedView";
NSString* const WMFSavedSortedByDateUngroupedView                                                                     = @"WMFSavedSortedByDateUngroupedView";
NSString* const WMFHistoryOrSavedSortedByURLUngroupedView                                                             = @"WMFHistoryOrSavedSortedByURLUngroupedView";
NSString* const WMFBlackListSortedByURLUngroupedView                                                                  = @"WMFBlackListSortedByURLUngroupedView";
NSString* const WMFHistoryOrSavedSortedByURLUngroupedFilteredBySignificnatlyViewedAndNotBlacklistedAndNotMainPageView = @"WMFHistoryOrSavedSortedByURLUngroupedFilteredBySignificnatlyViewedAndNotBlacklistedAndNotMainPageView";
NSString* const WMFNotInHistorySavedOrBlackListSortedByURLUngroupedView                                               = @"WMFNotInHistorySavedOrBlackListSortedByURLUngroupedView";

- (YapDatabaseViewMappings*)wmf_ungroupedMappingsWithView:(NSString*)viewName {
    return [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL (NSString* _Nonnull group, YapDatabaseReadTransaction* _Nonnull transaction) {
        return YES;
    } sortBlock:^NSComparisonResult (NSString* _Nonnull group1, NSString* _Nonnull group2, YapDatabaseReadTransaction* _Nonnull transaction) {
        return NSOrderedAscending;
    } view:viewName];
}

- (YapDatabaseViewMappings*)wmf_groupsSortedAlphabeticallyMappingsWithViewName:(NSString*)viewName {
    return [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL (NSString* _Nonnull group, YapDatabaseReadTransaction* _Nonnull transaction) {
        return YES;
    } sortBlock:^NSComparisonResult (NSString* _Nonnull group1, NSString* _Nonnull group2, YapDatabaseReadTransaction* _Nonnull transaction) {
        return [group1 localizedCaseInsensitiveCompare:group2];
    } view:viewName];
}

- (YapDatabaseViewMappings*)wmf_groupsAsTimeIntervalsSortedDescendingMappingsWithView:(NSString*)viewName {
    return [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL (NSString* _Nonnull group, YapDatabaseReadTransaction* _Nonnull transaction) {
        return YES;
    } sortBlock:^NSComparisonResult (NSString* _Nonnull group1, NSString* _Nonnull group2, YapDatabaseReadTransaction* _Nonnull transaction) {
        if ([group1 doubleValue] < [group2 doubleValue]) {
            return NSOrderedDescending;
        } else if ([group1 doubleValue] > [group2 doubleValue]) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    } view:viewName];
}

@end
