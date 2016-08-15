#import "UICollectionViewFlowLayout+WMFItemSizeThatFits.h"

@implementation UICollectionViewFlowLayout (WMFItemSizeThatFits)

- (CGSize)wmf_itemSizeThatFits:(CGSize)size {
    return CGSizeMake(fmaxf(size.width - self.sectionInset.left - self.sectionInset.right - self.minimumInteritemSpacing,
                            0.f),
                      fmaxf(size.height - self.sectionInset.top - self.sectionInset.bottom - self.minimumLineSpacing,
                            0.f));
}

- (void)wmf_itemSizeToFit {
    self.itemSize = [self wmf_itemSizeThatFits:self.collectionView.bounds.size];
}

- (void)wmf_strictItemSizeToFit {
    CGSize sizeThatFits = [self wmf_itemSizeThatFits:self.collectionView.bounds.size];
    NSParameterAssert(!CGSizeEqualToSize(sizeThatFits, CGSizeZero));
    self.itemSize = sizeThatFits;
}

@end
