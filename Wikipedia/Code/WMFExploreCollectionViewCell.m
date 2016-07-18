#import "WMFExploreCollectionViewCell.h"

@implementation WMFExploreCollectionViewCell

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)attributesToFit {
    CGSize sizeToFit = attributesToFit.size;
    
    CGSize fitSize = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    UICollectionViewLayoutAttributes *fitAttributes = [attributesToFit copy];
    fitSize.width = sizeToFit.width;
    fitAttributes.size = fitSize;

    return fitAttributes;
}

@end
