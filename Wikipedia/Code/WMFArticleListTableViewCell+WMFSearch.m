#import "WMFArticleListTableViewCell+WMFSearch.h"

@implementation WMFArticleListTableViewCell (WMFSearch)

+ (UIFont *)titleLabelFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

+ (UIFont *)titleLabelHighlightFont {
    return [UIFont wmf_preferredFontForFontFamily:WMFFontFamilySystemBold withTextStyle:UIFontTextStyleBody];
}

- (void)wmf_setTitleText:(NSString *)text highlightingText:(NSString *)highlightText {
    NSMutableAttributedString *attributedTitle =
        [[NSMutableAttributedString alloc] initWithString:text
                                               attributes:@{
                                                   NSFontAttributeName: [[self class] titleLabelFont]
                                               }];

    if (highlightText) {
        NSRange highlightRange = [text rangeOfString:highlightText options:NSCaseInsensitiveSearch];
        if (!WMFRangeIsNotFoundOrEmpty(highlightRange)) {
            [attributedTitle addAttribute:NSFontAttributeName
                                    value:[[self class] titleLabelHighlightFont]
                                    range:highlightRange];
        }
    }
    self.titleLabel.attributedText = attributedTitle;
}

@end
