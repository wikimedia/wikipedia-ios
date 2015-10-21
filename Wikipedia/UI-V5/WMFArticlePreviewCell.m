
#import "WMFArticlePreviewCell.h"
#import "WMFSaveableTitleCollectionViewCell+Subclass.h"

@interface WMFArticlePreviewCell ()

@property (strong, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel* summaryLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintLeading;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintTrailing;

@property (nonatomic) CGFloat paddingAboveDescriptionFromIB;
@property (nonatomic) CGFloat paddingBelowDescriptionFromIB;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintAboveDescription;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintBelowDescription;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* imageHeightConstraint;

@end

@implementation WMFArticlePreviewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.descriptionText             = nil;
    self.summaryLabel.attributedText = nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self rememberSettingsFromIB];
}

- (void)rememberSettingsFromIB {
    self.paddingAboveDescriptionFromIB = self.paddingConstraintAboveDescription.constant;
    self.paddingBelowDescriptionFromIB = self.paddingConstraintBelowDescription.constant;
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
    if (self.descriptionLabel.text.length == 0) {
        [self removeDescriptionVerticalPadding];
    } else {
        [self restoreDescriptionVerticalPadding];
    }
}

- (void)removeDescriptionVerticalPadding {
    self.paddingConstraintAboveDescription.constant = 0;
    self.paddingConstraintBelowDescription.constant = 0;
}

- (void)restoreDescriptionVerticalPadding {
    self.paddingConstraintAboveDescription.constant = self.paddingAboveDescriptionFromIB;
    self.paddingConstraintBelowDescription.constant = self.paddingBelowDescriptionFromIB;
}

- (void)setSummary:(NSString*)summary {
    if (!summary.length) {
        self.summaryLabel.attributedText = nil;
        return;
    }
    self.summaryLabel.attributedText = [[NSAttributedString alloc] initWithString:summary attributes:self.summaryAttributes];
}

- (NSDictionary*)summaryAttributes {
    static NSDictionary* attributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle alloc] init];
        pStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        pStyle.baseWritingDirection = NSWritingDirectionNatural;
        pStyle.lineHeightMultiple = 1.35;
        attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                       NSForegroundColorAttributeName: [UIColor blackColor],
                       NSParagraphStyleAttributeName: pStyle};
    });
    return attributes;
}

- (void)setImageURL:(NSURL*)imageURL {
    [super setImageURL:imageURL];
    if (imageURL) {
        [self restoreImageToFullHeight];
    } else {
        [self collapseImageHeightToZero];
    }
}

- (void)setImage:(MWKImage*)image {
    [super setImage:image];
    if (image) {
        [self restoreImageToFullHeight];
    } else {
        [self collapseImageHeightToZero];
    }
}

- (void)collapseImageHeightToZero {
    self.imageHeightConstraint.constant = 0;
}

- (void)restoreImageToFullHeight {
    self.imageHeightConstraint.constant = [self sixteenByNineHeightForImageWithSameHeightForLandscape];
}

- (CGFloat)sixteenByNineHeightForImageWithSameHeightForLandscape {
    // Design said landscape should use same height used for portrait.
    CGFloat horizontalPadding = self.paddingConstraintLeading.constant + self.paddingConstraintTrailing.constant;
    CGFloat ratio             = (9.0 / 16.0);
    return floor((MIN(CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds)) - horizontalPadding) * ratio);
}

@end
