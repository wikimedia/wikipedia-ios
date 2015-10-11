
#import "WMFArticlePreviewCell.h"
#import "WMFSaveableTitleCollectionViewCell+Subclass.h"

@interface WMFArticlePreviewCell ()

@property (strong, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel* summaryLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintLeading;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintTrailing;
@property (strong, nonatomic) NSDictionary* summaryLabelAttributesFromIB;

@end

@implementation WMFArticlePreviewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.descriptionText   = nil;
    self.summaryLabel.text = nil;
}

- (UICollectionViewLayoutAttributes*)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes*)layoutAttributes {
    CGFloat const preferredMaxLayoutWidth = layoutAttributes.size.width - (self.paddingConstraintLeading.constant + self.paddingConstraintTrailing.constant);

    self.titleLabel.preferredMaxLayoutWidth       = preferredMaxLayoutWidth;
    self.descriptionLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
    self.summaryLabel.preferredMaxLayoutWidth     = preferredMaxLayoutWidth;

    UICollectionViewLayoutAttributes* preferredAttributes = [layoutAttributes copy];

    preferredAttributes.size = CGSizeMake(layoutAttributes.size.width, [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
    return preferredAttributes;
}

- (void)setDescriptionText:(NSString*)descriptionText {
    _descriptionText           = descriptionText;
    self.descriptionLabel.text = descriptionText;
}

- (void)setSummary:(NSString*)summary {
    if (!self.summaryLabelAttributesFromIB) {
        NSRange r = NSMakeRange(0, 1);
        self.summaryLabelAttributesFromIB = [self.summaryLabel.attributedText attributesAtIndex:0 effectiveRange:&r];
    }

    if (!summary.length) {
        self.summaryLabel.attributedText = nil;
        return;
    }
    self.summaryLabel.attributedText = [[NSAttributedString alloc] initWithString:summary attributes:self.summaryLabelAttributesFromIB];
}

@end
