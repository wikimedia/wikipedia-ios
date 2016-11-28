#import "WMFExploreCollectionViewCell.h"

@implementation WMFExploreCollectionViewCell

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)attributesToFit {

    CGFloat requiredWidth = attributesToFit.size.width;

    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:requiredWidth];

    [self addConstraint:widthConstraint];
    CGSize fitSize = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    [self removeConstraint:widthConstraint];

    if (CGSizeEqualToSize(fitSize, attributesToFit.size)) {
        return attributesToFit;
    } else {
        UICollectionViewLayoutAttributes *fitAttributes = [attributesToFit copy];
        fitSize.width = requiredWidth;
        if (fitSize.height == CGFLOAT_MAX) {
            fitSize.height = attributesToFit.size.height;
        }

        fitAttributes.frame = (CGRect){attributesToFit.frame.origin, fitSize};
        return fitAttributes;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.backgroundColor = highlighted ? [UIColor wmf_tapHighlightColor] : [UIColor whiteColor];
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
