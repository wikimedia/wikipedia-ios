
#import "WMFNearbySectionEmptyCell.h"

@implementation WMFNearbySectionEmptyCell

- (void)awakeFromNib {
    self.emptyTextLabel.text = MWLocalizedString(@"home-nearby-nothing", nil);
    [self.reloadButton setTitle:MWLocalizedString(@"home-nearby-check-again", nil) forState:UIControlStateNormal];
}

- (UICollectionViewLayoutAttributes*)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes*)layoutAttributes {
    UICollectionViewLayoutAttributes* preferredAttributes = [layoutAttributes copy];
    preferredAttributes.size = CGSizeMake(layoutAttributes.size.width, 250);
    return preferredAttributes;
}

@end
