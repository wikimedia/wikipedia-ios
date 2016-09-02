#import <UIKit/UIKit.h>

@interface UICollectionViewFlowLayout (WMFItemSizeThatFits)

/**
 * Calculate a @c CGSize that fills @c size, minus any spacing or inset configured on the receiver.
 * @param size The size an item should try to fill.
 * @return The fitting @c CGSize, or @c CGSizeZero if the specified size is too small.
 */
- (CGSize)wmf_itemSizeThatFits:(CGSize)size;

/// Set the receiver's @c itemSize to fit within the bounds of its @c collectionView.
- (void)wmf_itemSizeToFit;

/// Equivalent to @c -wmf_itemSizeToFit, but will raise an assertion if the fitting @c itemSize is @c CGSizeZero.
- (void)wmf_strictItemSizeToFit;

@end
