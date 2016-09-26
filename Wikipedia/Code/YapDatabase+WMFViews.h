#import <YapDatabase/YapDatabase.h>
#import <YapDataBase/YapDatabaseView.h>
#import <YapDataBase/YapDatabaseFilteredView.h>

@interface YapDatabase (WMFViews)

#pragma mark - View Components
/**
 *  The following components can be combined to create views in the database.
 *
 *  Views are constructed using a YapDatabaseViewGrouping and a YapDatabaseViewSorting object.
 *  Existing views can be filtered applying a YapDatabaseViewFiltering
 *
 *  Once registered, views can be referenced by their view name on a specific connection.
 */

- (YapDatabaseViewGrouping *)wmf_historyGroupingSingleGroup;
- (YapDatabaseViewGrouping *)wmf_savedGroupingSingleGroup;
- (YapDatabaseViewGrouping *)wmf_historyOrSavedGroupingSingleGroup;
- (YapDatabaseViewGrouping *)wmf_historyGroupingByDate;

- (YapDatabaseViewGrouping *)wmf_blackListGroupingSingleGroup;
- (YapDatabaseViewGrouping *)wmf_notInHistorySavedOrBlackListGroupingSingleGroup;

- (YapDatabaseViewSorting *)wmf_historySortedByDateDescending;
- (YapDatabaseViewSorting *)wmf_savedSortedByDateDescending;
- (YapDatabaseViewSorting *)wmf_historyOrSavedSortedByURL;

- (YapDatabaseViewFiltering *)wmf_historyOrSavedSignificantlyViewedAndNotBlacklistedAndNotMainPageFilter;
- (YapDatabaseViewFiltering *)wmf_excludedKeysFilter:(NSArray<NSString *> *)keysToExclude;

- (YapDatabaseViewFiltering *)wmf_objectWithKeyFilter:(NSString *)databaseKey;

#pragma mark - Registered View Names
/**
 *  Views are given a name when registered in the DB
 *  It is recommended that all view names be documented here to:
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

/**
 *  Register the views with the names included above.
 *  If you create a new peristent view, you should register it within this method.
 */
- (void)wmf_registerViews;

#pragma mark - Mappings
/**
 *  Mappings are used to sort groups in to sections fit for collection views / table views
 *  Mappings are required for views with multiple sections that must be displayed in a collection view or table view. They are not for views with a single section.
 *  Mappings are also useful for views with single groups simply to provide access via indexPath.
 *
 *  Although mappings are separate objects, they are explicitly tied to a view on a instantiation
 */

/**
 *  Mappings for Views without groups. 
 *  Since there is only a single group, the group sort is undefined.
 *
 *  @param viewName The view to apply mappings to
 *
 *  @return The mapings
 */
- (YapDatabaseViewMappings *)wmf_ungroupedMappingsWithView:(NSString *)viewName;

/**
 *  Sort group names alphabetically.
 *
 *  @param viewName The view to apply mappings to
 *
 *  @return The mappings
 */
- (YapDatabaseViewMappings *)wmf_groupsSortedAlphabeticallyMappingsWithViewName:(NSString *)viewName;

/**
 *  Mappings for Views where group names are stringified NSTimeIntervals 
 *  This sorts them in descending order.
 *
 *  @param viewName The view to apply mappings to
 *
 *  @return The mappings
 */
- (YapDatabaseViewMappings *)wmf_groupsAsTimeIntervalsSortedDescendingMappingsWithView:(NSString *)viewName;

@end
