#import <YapDataBase/YapDatabaseView.h>

/**
 *  Mappings are used to sort groups in to sections fit for collection views / table views
 *
 *  Although mappings are separate objects, they are explicitly tied to a view on a instantiation
 */

@interface YapDatabaseViewMappings (WMFMappings)

/**
 *  Mappings for Views without groups.
 *  Since there is only a single group, the group sort is undefined.
 *
 *  @param viewName The view to apply mappings to
 *
 *  @return The mapings
 */
+ (YapDatabaseViewMappings *)wmf_ungroupedMappingsWithView:(NSString *)viewName;

/**
 *  Sort group names alphabetically.
 *
 *  @param viewName The view to apply mappings to
 *
 *  @return The mappings
 */
+ (YapDatabaseViewMappings *)wmf_groupsSortedAlphabeticallyMappingsWithViewName:(NSString *)viewName;

/**
 *  Mappings for Views where group names are stringified NSTimeIntervals
 *  This sorts them in descending order.
 *
 *  @param viewName The view to apply mappings to
 *
 *  @return The mappings
 */
+ (YapDatabaseViewMappings *)wmf_groupsAsTimeIntervalsSortedDescendingMappingsWithView:(NSString *)viewName;

@end
