
#import "WMFArticleListTableViewCell.h"
#import "UIColor+WMFStyle.h"
#import "UIImage+WMFStyle.h"
#import "UIImageView+WMFImageFetching.h"
#import "WMFRangeUtils.h"
#import "NSParagraphStyle+WMFParagraphStyles.h"

@implementation WMFArticleListTableViewCell

- (void)configureImageViewWithPlaceholder {
    self.articleImageView.tintColor = [UIColor wmf_placeholderImageTintColor];
    self.articleImageView.image     = [UIImage wmf_placeholderImage];
}

- (void)configureCell {
    [self configureContentView];
    [self configureImageViewWithPlaceholder];
}

- (void)configureContentView {
    self.clipsToBounds               = NO;
    self.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.titleLabel.text = nil;
    [self.articleImageView wmf_reset];
    [self configureImageViewWithPlaceholder];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureImageViewWithPlaceholder];
}

#pragma mark - Style

+ (CGFloat)titleLabelFontSize {
    return 16.f;
}

+ (UIFont*)titleLabelFont {
    return [UIFont systemFontOfSize:[self titleLabelFontSize]];
}

+ (UIFont*)boldTitleLabelFont {
    return [UIFont boldSystemFontOfSize:[self titleLabelFontSize]];
}

- (void)updateTitleLabelWithText:(NSString*)text highlightingText:(NSString*)highlightText {
    if (highlightText.length == 0) {
        self.titleLabel.text = text;
        return;
    }

    NSRange highlightRange = [text rangeOfString:highlightText options:NSCaseInsensitiveSearch];
    if (WMFRangeIsNotFoundOrEmpty(highlightRange)) {
        self.titleLabel.text = text;
        return;
    }

    NSMutableAttributedString* attributedTitle =
        [[NSMutableAttributedString alloc] initWithString:text attributes:nil];

    NSRange beforeHighlight = NSMakeRange(0, highlightRange.location);
    if (!WMFRangeIsNotFoundOrEmpty(beforeHighlight)) {
        [attributedTitle addAttribute:NSFontAttributeName
                                value:[[self class] titleLabelFont]
                                range:beforeHighlight];
    }

    [attributedTitle addAttribute:NSFontAttributeName
                            value:[[self class] boldTitleLabelFont]
                            range:highlightRange];

    NSUInteger afterHighlightStart = WMFRangeGetMaxIndex(highlightRange) - 1;
    NSRange afterHighlight         = NSMakeRange(afterHighlightStart, text.length - afterHighlightStart);
    if (!WMFRangeIsNotFoundOrEmpty(afterHighlight)) {
        [attributedTitle addAttribute:NSFontAttributeName
                                value:[[self class] titleLabelFont]
                                range:beforeHighlight];
    }

    [attributedTitle addAttribute:NSParagraphStyleAttributeName
                            value:[NSParagraphStyle wmf_tailTruncatingNaturalAlignmentStyle]
                            range:NSMakeRange(0, text.length)];

    self.titleLabel.attributedText = attributedTitle;
}

@end
