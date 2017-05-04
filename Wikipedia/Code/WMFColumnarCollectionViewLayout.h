#import <UIKit/UIKit.h>

@class WMFCVLMetrics;

/*!
 @class        WMFColumnarCollectionViewLayout
 @abstract     A WMFColumnarCollectionViewLayout organizes a collection view into columns grouped by section - all items from the same section will be in the same column.
 @discussion   ...
 */
@interface WMFColumnarCollectionViewLayout : UICollectionViewLayout

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesAtPoint:(CGPoint)point; //returns the first matched layout attributes that contain the given point

@property (nonatomic) BOOL slideInNewContentFromTheTop;

@end

struct WMFLayoutEstimate {
    BOOL precalculated;
    CGFloat height;
};
typedef struct WMFLayoutEstimate WMFLayoutEstimate;

@protocol WMFColumnarCollectionViewLayoutDelegate <UICollectionViewDelegate>
@required
- (WMFLayoutEstimate)collectionView:(nonnull UICollectionView *)collectionView estimatedHeightForItemAtIndexPath:(nonnull NSIndexPath *)indexPath forColumnWidth:(CGFloat)columnWidth;
- (CGFloat)collectionView:(nonnull UICollectionView *)collectionView estimatedHeightForHeaderInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth;
- (CGFloat)collectionView:(nonnull UICollectionView *)collectionView estimatedHeightForFooterInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth;
- (BOOL)collectionView:(nonnull UICollectionView *)collectionView prefersWiderColumnForSectionAtIndex:(NSUInteger)index;

@end
