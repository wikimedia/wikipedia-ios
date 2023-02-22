#import "NSAttributedString+WMFSavedPagesAttributedStrings.h"
#import "NSString+FormattedAttributedString.h"
@import WMF;

static CGFloat const kTitleFontSize = 21.0f;

static CGFloat const kDescriptionFontSize = 13.0f;
static CGFloat const kDescriptionSpaceAbove = 3.0f;

static CGFloat const kLanguageFontSize = 10.0f;
static CGFloat const kLanguageSpaceAbove = 5.0f;

static NSString *const kLineBreak = @"\n";
static NSString *const kFormatString = @"$1$2$3$4$5";

@implementation NSAttributedString (WMFSavedPagesAttributedStrings)

+ (NSAttributedString *)wmf_attributedStringWithTitle:(NSString *)title
                                          description:(NSString *)description
                                         languageCode:(NSString *)languageCode {
    description = [description wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguageCode:languageCode];

    // Shrink super long titles.
    CGFloat titleSizeMultiplier = 1.0f;
    if (title.length > 100) {
        titleSizeMultiplier = 0.75f;
    }

    NSDictionary *titleAttribs =
        @{
            NSFontAttributeName: [UIFont systemFontOfSize:titleSizeMultiplier * kTitleFontSize],
            NSForegroundColorAttributeName: [UIColor base0]
        };

    static NSDictionary *descripAttribs = nil;
    if (!descripAttribs) {
        NSMutableParagraphStyle *descParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        descParagraphStyle.paragraphSpacingBefore = kDescriptionSpaceAbove;
        descripAttribs = @{
            NSFontAttributeName: [UIFont systemFontOfSize:kDescriptionFontSize],
            NSForegroundColorAttributeName: [UIColor attributedStringGreyDescription],
            NSParagraphStyleAttributeName: descParagraphStyle
        };
    }

    static NSDictionary *langAttribs = nil;
    if (!langAttribs) {
        NSMutableParagraphStyle *langParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        langParagraphStyle.paragraphSpacingBefore = kLanguageSpaceAbove;
        langAttribs = @{
            NSFontAttributeName: [UIFont systemFontOfSize:kLanguageFontSize],
            NSForegroundColorAttributeName: [UIColor attributedStringGreyLanguage],
            NSParagraphStyleAttributeName: langParagraphStyle
        };
    }

    NSString *descripLineBreak = (description.length == 0) ? @"" : kLineBreak;
    description = description ? description : @"";
    languageCode = languageCode ? languageCode : @"";

    return
        [kFormatString attributedStringWithAttributes:@{}
                                  substitutionStrings:@[title, kLineBreak, description, descripLineBreak, languageCode]
                               substitutionAttributes:@[titleAttribs, @{}, descripAttribs, @{}, langAttribs]];
}

@end
