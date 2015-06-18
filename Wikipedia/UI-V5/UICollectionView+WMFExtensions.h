
@import UIKit;

@interface UICollectionView (WMFExtensions)

- (void)wmf_enumerateIndexPathsUsingBlock:(void (^)(NSIndexPath* indexPath, BOOL* stop))block;

- (void)wmf_enumerateVisibleIndexPathsUsingBlock:(void (^)(NSIndexPath* indexPath, BOOL* stop))block;

/**
 *  Like other UIKit methods, the completion isn't called if you pass animated = false.
 *  This method ensures the completion block is always called.
 */
- (void)wmf_setCollectionViewLayout:(UICollectionViewLayout*)layout animated:(BOOL)animated alwaysFireCompletion:(void (^)(BOOL finished))completion;

@end
