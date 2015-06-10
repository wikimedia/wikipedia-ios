
@import UIKit;

@interface UICollectionView (WMFEnumeration)

- (void)wmf_enumerateIndexPathsUsingBlock:(void (^)(NSIndexPath* indexPath, BOOL* stop))block;

- (void)wmf_enumerateVisibleIndexPathsUsingBlock:(void (^)(NSIndexPath* indexPath, BOOL* stop))block;

@end
