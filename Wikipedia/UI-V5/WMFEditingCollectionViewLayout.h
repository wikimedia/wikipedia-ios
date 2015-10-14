
#import <UIKit/UIKit.h>
#import <SelfSizingWaterfallCollectionViewLayout/SelfSizingWaterfallCollectionViewLayout.h>

@protocol WMFEditingCollectionViewLayoutDelegate;

@interface WMFEditingCollectionViewLayout : SelfSizingWaterfallCollectionViewLayout

@property (nonatomic, weak) id<WMFEditingCollectionViewLayoutDelegate> editingDelegate;

@end


@protocol WMFEditingCollectionViewLayoutDelegate <NSObject>

@optional

/** Check whether a given cell can be moved.
 *
 *
 * Implement this method to prevent items from
 * being dragged to another location.
 *
 * @param layout The layout requesting the information
 * @param indexPath Index path of item to be moved.
 *
 * @return YES if item can be moved (default); otherwise NO.
 */
- (BOOL)editingLayout:(WMFEditingCollectionViewLayout*)layout canMoveItemAtIndexPath:(NSIndexPath*)indexPath;

/** Retarget a item's proposed index path while being moved.
 *
 * Implement this method to modify an item's target location
 * while being dragged to another location, e.g. to prevent
 * it from being moved to certain locations.
 *
 * @param layout The layout requesting the information
 * @param sourceIndexPath Moving item's original index path.
 * @param proposedDestinationIndexPath The item's proposed index path during move.
 *
 * @return The item's desired index path. Return proposedDestinationIndexPath if
 *         it is suitable (default); or nil if item should not be moved.
 */
- (NSIndexPath*)editingLayout:(WMFEditingCollectionViewLayout*)layout targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath*)sourceIndexPath toProposedIndexPath:(NSIndexPath*)proposedDestinationIndexPath;

/** Move item in data source while dragging.
 *
 * Implement this method to update the collection
 * view's data source.
 *
 * @param layout The layout making the movee
 * @param fromIndexPath Original item indexPath
 * @param toIndexPath New item indexPath
 */
- (void)editingLayout:(WMFEditingCollectionViewLayout*)layout moveItemAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath;


- (BOOL)editingLayout:(WMFEditingCollectionViewLayout*)layout canDeleteItemAtIndexPath:(NSIndexPath*)indexPath;

- (void)editingLayout:(WMFEditingCollectionViewLayout*)layout deleteItemAtIndexPath:(NSIndexPath*)indexPath;

@end