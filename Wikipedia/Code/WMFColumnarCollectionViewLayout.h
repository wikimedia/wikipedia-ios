#import <UIKit/UIKit.h>

@class WMFCVLMetrics;

/*!
 @class        WMFColumnarCollectionViewLayout
 @abstract     A WMFColumnarCollectionViewLayout organizes a collection view into columns grouped by section - all items from the same section will be in the same column.
 @discussion   ...
 */
@interface WMFColumnarCollectionViewLayout : UICollectionViewLayout

- (nonnull instancetype)initWithMetrics:(nonnull WMFCVLMetrics *)metrics NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

@protocol WMFColumnarCollectionViewLayoutDelegate <UICollectionViewDelegate>

@required
- (CGFloat)collectionView:(nonnull UICollectionView *)collectionView estimatedHeightForItemAtIndexPath:(nonnull NSIndexPath *)indexPath forColumnWidth:(CGFloat)columnWidth;
- (CGFloat)collectionView:(nonnull UICollectionView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth;
- (CGFloat)collectionView:(nonnull UICollectionView *)tableView estimatedHeightForFooterInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth;

@end