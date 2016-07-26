#import "WMFExploreCollectionViewCell.h"

@implementation WMFExploreCollectionViewCell

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)attributesToFit {
    CGSize sizeToFit = attributesToFit.size;
    sizeToFit.height = 0;
    
    CGSize fitSize = [self systemLayoutSizeFittingSize:sizeToFit withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];

    if (CGSizeEqualToSize(fitSize, attributesToFit.size)) {
        return attributesToFit;
    } else {
        UICollectionViewLayoutAttributes *fitAttributes = [attributesToFit copy];
        fitSize.width = sizeToFit.width;
        if (fitSize.height == CGFLOAT_MAX) {
            fitSize.height = attributesToFit.size.height;
        }
        fitAttributes.size = fitSize;
        return fitAttributes;
    }
}

@end
