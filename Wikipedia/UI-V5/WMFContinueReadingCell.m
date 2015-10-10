
#import "WMFContinueReadingCell.h"

@implementation WMFContinueReadingCell

- (UICollectionViewLayoutAttributes*)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes*)layoutAttributes {
    CGFloat const preferredMaxLayoutWidth = layoutAttributes.size.width - self.leadingConstraint.constant - self.trailingConstraint.constant;

    self.title.preferredMaxLayoutWidth   = preferredMaxLayoutWidth;
    self.summary.preferredMaxLayoutWidth = preferredMaxLayoutWidth;

    //HACK: can't call [self systemLayoutSizeFittingSize:CGSizeMake(preferredMaxLayoutWidth, CGFLOAT_MAX)];
    // This causes an arithmetic crash from some sort of semi-infinite loop through this method
    CGSize titleSize   = [self.title systemLayoutSizeFittingSize:CGSizeMake(preferredMaxLayoutWidth, CGFLOAT_MAX)];
    CGSize summarySize = [self.summary systemLayoutSizeFittingSize:CGSizeMake(preferredMaxLayoutWidth, CGFLOAT_MAX)];
    CGSize size        = CGSizeMake(layoutAttributes.size.width, self.topConstraint.constant + titleSize.height + self.middleConstraint.constant + summarySize.height + self.bottomConstraint.constant);

    UICollectionViewLayoutAttributes* preferredAttributes = [layoutAttributes copy];
    preferredAttributes.size = size;

    return preferredAttributes;
}

@end
