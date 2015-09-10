
#import "WMFArticlePreviewCell.h"
#import "WMFSaveableTitleCollectionViewCell+Subclass.h"

#import "NSAttributedString+WMFModify.h"
#import "NSParagraphStyle+WMFParagraphStyles.h"
#import "NSAttributedString+WMFHTMLForSite.h"

CGFloat const WMFArticlePreviewCellTextPadding = 8.0;
CGFloat const WMFArticlePreviewCellImageHeight = 160;

@interface WMFArticlePreviewCell ()

@property (strong, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel* summaryLabel;

@end

@implementation WMFArticlePreviewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.descriptionText   = nil;
    self.summaryLabel.text = nil;
}

- (UICollectionViewLayoutAttributes*)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes*)layoutAttributes {
    CGFloat const preferredMaxLayoutWidth = layoutAttributes.size.width - 2 * WMFArticlePreviewCellTextPadding;

    self.titleLabel.preferredMaxLayoutWidth       = preferredMaxLayoutWidth;
    self.descriptionLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
    self.summaryLabel.preferredMaxLayoutWidth     = preferredMaxLayoutWidth;

    UICollectionViewLayoutAttributes* preferredAttributes = [layoutAttributes copy];
    CGFloat height                                        =
        WMFArticlePreviewCellImageHeight +
        MIN(200, self.summaryLabel.intrinsicContentSize.height + 2 * WMFArticlePreviewCellTextPadding);
    preferredAttributes.size = CGSizeMake(layoutAttributes.size.width, height);
    return preferredAttributes;
}

- (void)setDescriptionText:(NSString*)descriptionText {
    _descriptionText           = descriptionText;
    self.descriptionLabel.text = descriptionText;
}

- (void)setSummaryAttributedText:(NSAttributedString*)summaryAttributedText {
    if (!summaryAttributedText.string.length) {
        self.summaryLabel.text = nil;
        return;
    }

    summaryAttributedText = [summaryAttributedText
                             wmf_attributedStringChangingAttribute:NSParagraphStyleAttributeName
                                                         withBlock:^NSParagraphStyle*(NSParagraphStyle* paragraphStyle){
        NSMutableParagraphStyle* style = paragraphStyle.mutableCopy;
        style.lineBreakMode = NSLineBreakByTruncatingTail;
        return style;
    }];

    NSMutableAttributedString* text = [summaryAttributedText mutableCopy];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor wmf_summaryTextColor] range:NSMakeRange(0, text.length)];

    self.summaryLabel.attributedText = text;
}

- (void)setSummaryHTML:(NSString*)summaryHTML fromSite:(MWKSite*)site {
    if (!summaryHTML.length) {
        self.summaryLabel.text = nil;
        return;
    }

    NSAttributedString* summaryAttributedText =
        [[NSAttributedString alloc] initWithHTMLData:[summaryHTML dataUsingEncoding:NSUTF8StringEncoding] site:site];

    [self setSummaryAttributedText:summaryAttributedText];
}

@end
