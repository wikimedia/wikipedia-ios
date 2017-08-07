#import "WMFExploreCollectionViewCell.h"
#import "WMFCVLAttributes.h"
@import WMF.Swift;
@import WMF.WMFCVLAttributes;

@implementation WMFExploreCollectionViewCell

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)attributesToFit {
    if ([attributesToFit isKindOfClass:[WMFCVLAttributes class]] && [(WMFCVLAttributes *)attributesToFit precalculated]) {
        return attributesToFit;
    }
    CGSize sizeToFit = attributesToFit.size;
    sizeToFit.height = UIViewNoIntrinsicMetric;

    CGSize fitSize = [self.contentView systemLayoutSizeFittingSize:sizeToFit withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];

    if (CGSizeEqualToSize(fitSize, attributesToFit.size)) {
        return attributesToFit;
    } else {
        UICollectionViewLayoutAttributes *fitAttributes = [attributesToFit copy];
        fitSize.width = sizeToFit.width;
        if (fitSize.height == CGFLOAT_MAX) {
            fitSize.height = attributesToFit.size.height;
        }

        fitAttributes.frame = (CGRect){attributesToFit.frame.origin, fitSize};
        return fitAttributes;
    }
}

@end

@implementation WMFExploreCollectionReusableView

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)attributesToFit {
    if ([attributesToFit isKindOfClass:[WMFCVLAttributes class]] && [(WMFCVLAttributes *)attributesToFit precalculated]) {
        return attributesToFit;
    }
    CGSize sizeToFit = attributesToFit.size;
    sizeToFit.height = UIViewNoIntrinsicMetric;

    CGSize fitSize = [self systemLayoutSizeFittingSize:sizeToFit withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];

    if (CGSizeEqualToSize(fitSize, attributesToFit.size)) {
        return attributesToFit;
    } else {
        UICollectionViewLayoutAttributes *fitAttributes = [attributesToFit copy];
        fitSize.width = sizeToFit.width;
        if (fitSize.height == CGFLOAT_MAX) {
            fitSize.height = attributesToFit.size.height;
        }

        fitAttributes.frame = (CGRect){attributesToFit.frame.origin, fitSize};
        return fitAttributes;
    }
}
@end
