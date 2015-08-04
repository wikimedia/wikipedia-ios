@import UIKit;

NS_ASSUME_NONNULL_BEGIN

typedef void (^ WMFIndexPathEnumerator)(NSIndexPath* indexPath, BOOL* stop);
typedef void (^ WMFCellEnumerator)(id cell, NSIndexPath* indexPath, BOOL* stop);

@interface UICollectionView (WMFExtensions)

- (NSArray*)wmf_indexPathsForIndexes:(NSIndexSet*)indexes inSection:(NSInteger)section;

- (void)wmf_enumerateIndexPathsUsingBlock:(WMFIndexPathEnumerator)block;

- (void)wmf_enumerateVisibleIndexPathsUsingBlock:(WMFIndexPathEnumerator)block;

- (void)wmf_enumerateVisibleCellsUsingBlock:(WMFCellEnumerator)block;

- (NSIndexPath*)wmf_indexPathBeforeIndexPath:(NSIndexPath*)indexPath;
- (NSIndexPath*)wmf_indexPathAfterIndexPath:(NSIndexPath*)indexPath;

/**
 *  Like other UIKit methods, the completion isn't called if you pass animated = false.
 *  This method ensures the completion block is always called.
 */
- (void)wmf_setCollectionViewLayout:(UICollectionViewLayout*)layout animated:(BOOL)animated alwaysFireCompletion:(void (^)(BOOL finished))completion;

- (NSArray*)wmf_visibleIndexPathsOfItemsBeforeIndexPath:(NSIndexPath*)indexPath;

- (NSArray*)wmf_visibleIndexPathsOfItemsAfterIndexPath:(NSIndexPath*)indexPath;

- (CGRect)wmf_rectEnclosingCellsAtIndexPaths:(NSArray*)indexPaths;

- (UIView*)wmf_snapshotOfVisibleCells;

- (UIView*)wmf_snapshotOfCellAtIndexPath:(NSIndexPath*)indexPath;

- (UIView*)wmf_snapshotOfCellsAtIndexPaths:(NSArray*)indexPaths;

- (UIView*)wmf_snapshotOfCellsBeforeIndexPath:(NSIndexPath*)indexPath;

- (UIView*)wmf_snapshotOfCellsAfterIndexPath:(NSIndexPath*)indexPath;


@end

NS_ASSUME_NONNULL_END
