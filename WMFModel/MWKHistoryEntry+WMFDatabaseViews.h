#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import "WMFDatabaseViewable.h"

#pragma mark - Registered View Names
/**
 *  Views are given a name when registered in the DB
 *
 *  1. Make them public so others can reference them
 *  2. Make sure the names are not duplicated (view names must be unique)
 */

/**
 *  historyOrSavedGroupingSingleGroup + historySortedByDateDescending
 */
extern NSString *const WMFHistorySortedByDateGroupedByDateView;

/**
 *  historyGroupingSingleGroup + historySortedByDateDescending
 */
extern NSString *const WMFHistorySortedByDateUngroupedView;

/**
 *  savedGroupingSingleGroup + savedSortedByDateDescending
 */
extern NSString *const WMFSavedSortedByDateUngroupedView;

/**
 *  historyOrSavedGroupingSingleGroup + historyOrSavedSortedByURL
 */
extern NSString *const WMFHistoryOrSavedSortedByURLUngroupedView;

/**
 *  blackListGroupingSingleGroup + historyOrSavedSortedByURL
 */
extern NSString *const WMFBlackListSortedByURLUngroupedView;

/**
 *  historyOrSavedSignificantlyViewedAndNotBlacklistedAndNotMainPageFilter + WMFHistoryOrSavedSortedByURLUngroupedView
 */
extern NSString *const WMFHistoryOrSavedSortedByURLUngroupedFilteredBySignificantlyViewedAndNotBlacklistedAndNotMainPageView;

/**
 *  notInHistorySavedOrBlackListGroupingSingleGroup + historyOrSavedSortedByURL
 */
extern NSString *const WMFNotInHistorySavedOrBlackListSortedByURLUngroupedView;

@interface MWKHistoryEntry (WMFDatabaseViews) <WMFDatabaseViewable>

/**
 *  The following components can be combined to create user data views in the database.
 *
 *  Views are constructed using a YapDatabaseViewGrouping and a YapDatabaseViewSorting object.
 *  Existing views can be filtered applying a YapDatabaseViewFiltering
 *
 *  Once registered, views can be referenced by their view name on a specific connection.
 */
+ (YapDatabaseViewGrouping *)wmf_historyGroupingSingleGroup;
+ (YapDatabaseViewGrouping *)wmf_savedGroupingSingleGroup;
+ (YapDatabaseViewGrouping *)wmf_historyOrSavedGroupingSingleGroup;
+ (YapDatabaseViewGrouping *)wmf_historyGroupingByDate;

+ (YapDatabaseViewGrouping *)wmf_blackListGroupingSingleGroup;
+ (YapDatabaseViewGrouping *)wmf_notInHistorySavedOrBlackListGroupingSingleGroup;

+ (YapDatabaseViewSorting *)wmf_historySortedByDateDescending;
+ (YapDatabaseViewSorting *)wmf_savedSortedByDateDescending;
+ (YapDatabaseViewSorting *)wmf_historyOrSavedSortedByURL;

+ (YapDatabaseViewFiltering *)wmf_historyOrSavedSignificantlyViewedAndNotBlacklistedAndNotMainPageFilter;
+ (YapDatabaseViewFiltering *)wmf_excludedKeysFilter:(NSArray<NSString *> *)keysToExclude;

+ (YapDatabaseViewFiltering *)wmf_objectWithKeyFilter:(NSString *)databaseKey;

@end
