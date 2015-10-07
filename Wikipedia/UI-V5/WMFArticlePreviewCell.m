
#import "WMFArticlePreviewCell.h"
#import "WMFSaveableTitleCollectionViewCell+Subclass.h"

#import "NSAttributedString+WMFModify.h"
#import "NSParagraphStyle+WMFParagraphStyles.h"
#import "NSAttributedString+WMFHTMLForSite.h"

@interface WMFArticlePreviewCell ()

@property (strong, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel* summaryLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintLeading;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintTrailing;





/*
 
Todo:
- don't do summary as attributed string! No need based on mocks (an no more links)
- recent isn't captializing first descrip letter, feed is though.
- fix bug (pre-dates my patch) causing recent to not show summary of newly browsed-to article
    repro:
        -choose top recent article
        -click on link in that article
        -click back button to go back to recent list
        -top recent item will be the newly browsed-to link, but it's summary isn't showing until you scroll down a bit then back up
    solution?:
        -have the recent list call reloadData on view will appear?

 */





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
