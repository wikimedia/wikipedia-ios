#import "WMFExploreCollectionViewCell.h"
#import "WMFCVLAttributes.h"

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

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.backgroundColor = highlighted ? [UIColor wmf_tapHighlight] : [UIColor whiteColor];
    [self walkSubviewsOfView:self andSetHighlighted:highlighted];
}

- (void)walkSubviewsOfView:(UIView *)view andSetHighlighted:(BOOL)highlighted {
    for (id subview in view.subviews) {
        if ([subview respondsToSelector:@selector(setHighlighted:)]) {
            [subview setHighlighted:highlighted];
        }
        [self walkSubviewsOfView:subview andSetHighlighted:highlighted];
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

