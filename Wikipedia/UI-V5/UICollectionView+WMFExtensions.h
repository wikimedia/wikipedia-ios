
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

typedef void (^ WMFIndexPathEnumerator)(NSIndexPath* indexPath, BOOL* stop);
typedef void (^ WMFCellEnumerator)(id cell, NSIndexPath* indexPath, BOOL* stop);

@interface UICollectionView (WMFExtensions)

- (void)wmf_enumerateIndexPathsUsingBlock:(WMFIndexPathEnumerator)block;

- (void)wmf_enumerateVisibleIndexPathsUsingBlock:(WMFIndexPathEnumerator)block;

- (void)wmf_enumerateVisibleCellsUsingBlock:(WMFCellEnumerator)block;

/**
 *  Like other UIKit methods, the completion isn't called if you pass animated = false.
 *  This method ensures the completion block is always called.
 */
- (void)wmf_setCollectionViewLayout:(UICollectionViewLayout*)layout animated:(BOOL)animated alwaysFireCompletion:(void (^)(BOOL finished))completion;

@end

NS_ASSUME_NONNULL_END
