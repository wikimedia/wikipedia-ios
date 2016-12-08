#import "WMFArticleListTableViewCell+WMFSearch.h"

@implementation WMFArticleListTableViewCell (WMFSearch)

+ (UIFont *)titleLabelFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
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
            [attributedTitle addAttribute:NSBackgroundColorAttributeName
                                    value:[UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:0.3]
                                    range:highlightRange];
        }
    }
    self.titleLabel.attributedText = attributedTitle;
}

@end
