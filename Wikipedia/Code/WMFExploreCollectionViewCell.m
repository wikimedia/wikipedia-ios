#import "WMFExploreCollectionViewCell.h"
#import "WMFCVLAttributes.h"

@implementation WMFExploreCollectionViewCell

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)attributesToFit {

    UICollectionViewLayoutAttributes *fitAttributes = [attributesToFit copy];
    
    fitAttributes.frame = CGRectMake(
                                     attributesToFit.frame.origin.x,
                                     attributesToFit.frame.origin.y,
                                     attributesToFit.frame.size.width,
                                     [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height
                                     );
    
    return fitAttributes;
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
