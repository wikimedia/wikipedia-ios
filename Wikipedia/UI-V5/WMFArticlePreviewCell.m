
#import "WMFArticlePreviewCell.h"
#import "WMFSaveableTitleCollectionViewCell+Subclass.h"

@interface WMFArticlePreviewCell ()

@property (strong, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel* summaryLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintLeading;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintTrailing;

@property (strong, nonatomic) NSDictionary* summaryLabelAttributesFromIB;
@property (nonatomic) CGFloat paddingAboveDescriptionFromIB;
@property (nonatomic) CGFloat paddingBelowDescriptionFromIB;
@property (nonatomic) CGFloat heightOfImageFromIB;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintAboveDescription;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintBelowDescription;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* imageHeightConstraint;

@end

@implementation WMFArticlePreviewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.descriptionText   = nil;
    self.summaryLabel.text = nil;
}

-(void)awakeFromNib {
    [self rememberSettingsFromIB];
}

-(void)rememberSettingsFromIB {
    NSRange r = NSMakeRange(0, 1);
    self.summaryLabelAttributesFromIB = [self.summaryLabel.attributedText attributesAtIndex:0 effectiveRange:&r];
    self.paddingAboveDescriptionFromIB = self.paddingConstraintAboveDescription.constant;
    self.paddingBelowDescriptionFromIB = self.paddingConstraintBelowDescription.constant;
    self.heightOfImageFromIB = self.imageHeightConstraint.constant;
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
    if (!self.descriptionLabel.text || self.descriptionLabel.text.length == 0) {
        [self removeDescriptionVerticalPadding];
    }else{
        [self restoreDescriptionVerticalPadding];
    }
}

-(void)removeDescriptionVerticalPadding{
    self.paddingConstraintAboveDescription.constant = 0;
    self.paddingConstraintBelowDescription.constant = 0;
}

-(void)restoreDescriptionVerticalPadding{
    self.paddingConstraintAboveDescription.constant = self.paddingAboveDescriptionFromIB;
    self.paddingConstraintBelowDescription.constant = self.paddingBelowDescriptionFromIB;
}

- (void)setSummary:(NSString*)summary {
    if (!summary.length) {
        self.summaryLabel.attributedText = nil;
        return;
    }
    self.summaryLabel.attributedText = [[NSAttributedString alloc] initWithString:summary attributes:self.summaryLabelAttributesFromIB];
}

- (void)setImageURL:(NSURL*)imageURL {
    [super setImageURL:imageURL];
    if (imageURL) {
        [self restoreImageToFullHeight];
    }else{
        [self collapseImageHeightToZero];
    }
}

- (void)setImage:(MWKImage*)image {
    [super setImage:image];
    if (image) {
        [self restoreImageToFullHeight];
    }else{
        [self collapseImageHeightToZero];
    }
}

-(void)collapseImageHeightToZero{
    self.imageHeightConstraint.constant = 0;
}

-(void)restoreImageToFullHeight{
    self.imageHeightConstraint.constant = self.heightOfImageFromIB;
}

@end
