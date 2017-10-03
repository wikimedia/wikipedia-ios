#import "NSAttributedString+WMFSavedPagesAttributedStrings.h"
#import "NSString+FormattedAttributedString.h"
@import WMF;

static NSInteger const kTitleColor = 0x000000;
static CGFloat const kTitleFontSize = 21.0f;

static NSInteger const kDescriptionColor = 0x777777;
static CGFloat const kDescriptionFontSize = 13.0f;
static CGFloat const kDescriptionSpaceAbove = 3.0f;

static NSInteger const kLanguageColor = 0x999999;
static CGFloat const kLanguageFontSize = 10.0f;
static CGFloat const kLanguageSpaceAbove = 5.0f;

static NSString *const kLineBreak = @"\n";
static NSString *const kFormatString = @"$1$2$3$4$5";

@implementation NSAttributedString (WMFSavedPagesAttributedStrings)

+ (NSAttributedString *)wmf_attributedStringWithTitle:(NSString *)title
                                          description:(NSString *)description
                                             language:(NSString *)language {
    description = [description wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:language];

    // Shrink super long titles.
    CGFloat titleSizeMultiplier = 1.0f;
    if (title.length > 100) {
        titleSizeMultiplier = 0.75f;
    }

    NSDictionary *titleAttribs =
        @{
            NSFontAttributeName: [UIFont systemFontOfSize:titleSizeMultiplier * kTitleFontSize],
            NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kTitleColor]
        };

    static NSDictionary *descripAttribs = nil;
    if (!descripAttribs) {
        NSMutableParagraphStyle *descParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        descParagraphStyle.paragraphSpacingBefore = kDescriptionSpaceAbove;
        descripAttribs = @{
            NSFontAttributeName: [UIFont systemFontOfSize:kDescriptionFontSize],
            NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kDescriptionColor],
            NSParagraphStyleAttributeName: descParagraphStyle
        };
    }

    static NSDictionary *langAttribs = nil;
    if (!langAttribs) {
        NSMutableParagraphStyle *langParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        langParagraphStyle.paragraphSpacingBefore = kLanguageSpaceAbove;
        langAttribs = @{
            NSFontAttributeName: [UIFont systemFontOfSize:kLanguageFontSize],
            NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kLanguageColor],
            NSParagraphStyleAttributeName: langParagraphStyle
        };
    }

    NSString *descripLineBreak = (description.length == 0) ? @"" : kLineBreak;
    description = description ? description : @"";
    language = language ? language : @"";

    return
        [kFormatString attributedStringWithAttributes:@{}
                                  substitutionStrings:@[title, kLineBreak, description, descripLineBreak, language]
                               substitutionAttributes:@[titleAttribs, @{}, descripAttribs, @{}, langAttribs]];
}

@end
