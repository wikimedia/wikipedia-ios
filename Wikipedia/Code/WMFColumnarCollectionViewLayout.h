#import <UIKit/UIKit.h>

@interface WMFColumnarCollectionViewLayout : UICollectionViewLayout
@end

@protocol WMFColumnarCollectionViewLayoutDelegate <UICollectionViewDelegate>
@required
- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForItemAtIndexPath:(NSIndexPath *)indexPath forColumnWidth:(CGFloat)columnWidth;
- (CGFloat)collectionView:(UICollectionView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth;
- (CGFloat)collectionView:(UICollectionView *)tableView estimatedHeightForFooterInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth;
@end