#import "NSMutableAttributedStringHelper.h"
#import "Wikipedia-Swift.h"

// Public keys, used to determine if cursor / selection is in a particular formatting range
NSString *const kCustomAttributedStringKeyWikitextBold = @"kCustomAttributedStringKeyWikitextBold";
NSString *const kCustomAttributedStringKeyWikitextItalic = @"kCustomAttributedStringKeyWikitextItalic";
NSString *const kCustomAttributedStringKeyWikitextBoldAndItalic = @"kCustomAttributedStringKeyWikitextBoldAndItalic";
NSString *const kCustomAttributedStringKeyWikitextLink = @"kCustomAttributedStringKeyWikitextLink";
NSString *const kCustomAttributedStringKeyWikitextImage = @"kCustomAttributedStringKeyWikitextImage";
NSString *const kCustomAttributedStringKeyWikitextTemplate = @"kCustomAttributedStringKeyWikitextTemplate";
NSString *const kCustomAttributedStringKeyWikitextRef = @"kCustomAttributedStringKeyWikitextRef";
NSString *const kCustomAttributedStringKeyWikitextRefWithAttributes = @"kCustomAttributedStringKeyWikitextRefWithAttributes";
NSString *const kCustomAttributedStringKeyWikitextRefSelfClosing = @"kCustomAttributedStringKeyWikitextRefSelfClosing";
NSString *const kCustomAttributedStringKeyWikitextSuperscript = @"kCustomAttributedStringKeyWikitextSuperscript";
NSString *const kCustomAttributedStringKeyWikitextSubscript = @"kCustomAttributedStringKeyWikitextSubscript";
NSString *const kCustomAttributedStringKeyWikitextUnderline = @"kCustomAttributedStringKeyWikitextUnderline";
NSString *const kCustomAttributedStringKeyWikitextStrikethrough = @"kCustomAttributedStringKeyWikitextStrikethrough";
NSString *const kCustomAttributedStringKeyWikitextBullet = @"kCustomAttributedStringKeyWikitextBullet";
NSString *const kCustomAttributedStringKeyWikitextNumber = @"kCustomAttributedStringKeyWikitextNumber";
NSString *const kCustomAttributedStringKeyWikitextH2 = @"kCustomAttributedStringKeyWikitextH2";
NSString *const kCustomAttributedStringKeyWikitextH3 = @"kCustomAttributedStringKeyWikitextH3";
NSString *const kCustomAttributedStringKeyWikitextH4 = @"kCustomAttributedStringKeyWikitextH4";
NSString *const kCustomAttributedStringKeyWikitextH5 = @"kCustomAttributedStringKeyWikitextH5";
NSString *const kCustomAttributedStringKeyWikitextH6 = @"kCustomAttributedStringKeyWikitextH6";
NSString *const kCustomAttributedStringKeyWikitextComment = @"kCustomAttributedStringKeyWikitextComment";

// Public keys, used only for theming adjustment
NSString *const kCustomAttributedStringKeyColorLink = @"kCustomAttributedStringKeyColorLink";
NSString *const kCustomAttributedStringKeyColorTempate = @"kCustomAttributedStringKeyColorTempate";
NSString *const kCustomAttributedStringKeyColorHtmlTag = @"kCustomAttributedStringKeyColorHtmlTag";
NSString *const kCustomAttributedStringKeyColorComment = @"kCustomAttributedStringKeyColorComment";
NSString *const kCustomAttributedStringKeyColorShorthand = @"kCustomAttributedStringKeyColorShorthand";

// Public keys, used only for font size adjustment
NSString *const kCustomAttributedStringKeyFontBold = @"kCustomAttributedStringKeyFontBold";
NSString *const kCustomAttributedStringKeyFontItalic = @"kCustomAttributedStringKeyFontItalic";
NSString *const kCustomAttributedStringKeyFontBoldItalic = @"kCustomAttributedStringKeyFontBoldItalic";
NSString *const kCustomAttributedStringKeyFontH2 = @"kCustomAttributedStringKeyFontH2";
NSString *const kCustomAttributedStringKeyFontH3 = @"kCustomAttributedStringKeyFontH3";
NSString *const kCustomAttributedStringKeyFontH4 = @"kCustomAttributedStringKeyFontH4";
NSString *const kCustomAttributedStringKeyFontH5 = @"kCustomAttributedStringKeyFontH5";
NSString *const kCustomAttributedStringKeyFontH6 = @"kCustomAttributedStringKeyFontH6";

@interface NSMutableAttributedStringHelper ()

@property (strong, nonatomic) UIFontDescriptor *fontDescriptor;
@property (strong, nonatomic) UIFontDescriptor *boldFontDescriptor;
@property (strong, nonatomic) UIFontDescriptor *italicFontDescriptor;
@property (strong, nonatomic) UIFontDescriptor *boldItalicFontDescriptor;
@property (strong, nonatomic) UIFont *standardFont;
@property (strong, nonatomic) UIFont *boldFont;
@property (strong, nonatomic) UIFont *italicFont;
@property (strong, nonatomic) UIFont *boldItalicFont;
@property (strong, nonatomic) UIFont *h2Font;
@property (strong, nonatomic) UIFont *h3Font;
@property (strong, nonatomic) UIFont *h4Font;
@property (strong, nonatomic) UIFont *h5Font;
@property (strong, nonatomic) UIFont *h6Font;
@property (strong, nonatomic) NSString *boldItalicRegexStr;
@property (strong, nonatomic) NSString *boldRegexStr;
@property (strong, nonatomic) NSString *italicRegexStr;
@property (strong, nonatomic) NSString *linkRegexStr;
@property (strong, nonatomic) NSString *imageRegexStr;
@property (strong, nonatomic) NSString *sameLineTemplateRegexStr;
@property (strong, nonatomic) NSString *singleClosingTemplateRegexStr;
@property (strong, nonatomic) NSString *refRegexStr;
@property (strong, nonatomic) NSString *refWithAttributesRegexStr;
@property (strong, nonatomic) NSString *refSelfClosingRegexStr;
@property (strong, nonatomic) NSString *supRegexStr;
@property (strong, nonatomic) NSString *subRegexStr;
@property (strong, nonatomic) NSString *underlineRegexStr;
@property (strong, nonatomic) NSString *strikethroughRegexStr;
@property (strong, nonatomic) NSString *commentRegexStr;
@property (strong, nonatomic) NSString *h2RegexStr;
@property (strong, nonatomic) NSString *h3RegexStr;
@property (strong, nonatomic) NSString *h4RegexStr;
@property (strong, nonatomic) NSString *h5RegexStr;
@property (strong, nonatomic) NSString *h6RegexStr;
@property (strong, nonatomic) NSString *listBulletRegexStr;
@property (strong, nonatomic) NSString *listNumberRegexStr;
@property (strong, nonatomic) NSRegularExpression *boldItalicRegex;
@property (strong, nonatomic) NSRegularExpression *boldRegex;
@property (strong, nonatomic) NSRegularExpression *italicRegex;
@property (strong, nonatomic) NSRegularExpression *linkRegex;
@property (strong, nonatomic) NSRegularExpression *imageRegex;
@property (strong, nonatomic) NSRegularExpression *sameLineTemplateRegex;
@property (strong, nonatomic) NSRegularExpression *singleClosingTemplateRegex;
@property (strong, nonatomic) NSRegularExpression *refRegex;
@property (strong, nonatomic) NSRegularExpression *refWithAttributesRegex;
@property (strong, nonatomic) NSRegularExpression *refSelfClosingRegex;
@property (strong, nonatomic) NSRegularExpression *supRegex;
@property (strong, nonatomic) NSRegularExpression *subRegex;
@property (strong, nonatomic) NSRegularExpression *underlineRegex;
@property (strong, nonatomic) NSRegularExpression *strikethroughRegex;
@property (strong, nonatomic) NSRegularExpression *commentRegex;
@property (strong, nonatomic) NSRegularExpression *h2Regex;
@property (strong, nonatomic) NSRegularExpression *h3Regex;
@property (strong, nonatomic) NSRegularExpression *h4Regex;
@property (strong, nonatomic) NSRegularExpression *h5Regex;
@property (strong, nonatomic) NSRegularExpression *h6Regex;
@property (strong, nonatomic) NSRegularExpression *listBulletRegex;
@property (strong, nonatomic) NSRegularExpression *listNumberRegex;
@property (strong, nonatomic) NSDictionary *boldAttributes;
@property (strong, nonatomic) NSDictionary *italicAttributes;
@property (strong, nonatomic) NSDictionary *boldItalicAttributes;
@property (strong, nonatomic) NSDictionary *linkAttributes;
@property (strong, nonatomic) NSDictionary *templateAttributes;
@property (strong, nonatomic) NSDictionary *htmlTagAttributes;
@property (strong, nonatomic) NSDictionary *commentAttributes;
@property (strong, nonatomic) NSDictionary *orangeFontAttributes;
@property (strong, nonatomic) NSDictionary *h2FontAttributes;
@property (strong, nonatomic) NSDictionary *h3FontAttributes;
@property (strong, nonatomic) NSDictionary *h4FontAttributes;
@property (strong, nonatomic) NSDictionary *h5FontAttributes;
@property (strong, nonatomic) NSDictionary *h6FontAttributes;
@property (strong, nonatomic) NSDictionary *commonAttributes;
@property (strong, nonatomic) NSDictionary *wikitextBoldAttributes;
@property (strong, nonatomic) NSDictionary *wikitextItalicAttributes;
@property (strong, nonatomic) NSDictionary *wikitextBoldAndItalicAttributes;
@property (strong, nonatomic) NSDictionary *wikitextLinkAttributes;
@property (strong, nonatomic) NSDictionary *wikitextImageAttributes;
@property (strong, nonatomic) NSDictionary *wikitextTemplateAttributes;
@property (strong, nonatomic) NSDictionary *wikitextRefAttributes;
@property (strong, nonatomic) NSDictionary *wikitextSupAttributes;
@property (strong, nonatomic) NSDictionary *wikitextSubAttributes;
@property (strong, nonatomic) NSDictionary *wikitextCommentAttributes;
@property (strong, nonatomic) NSDictionary *wikitextUnderlineAttributes;
@property (strong, nonatomic) NSDictionary *wikitextStrikethroughAttributes;
@property (strong, nonatomic) NSDictionary *wikitextRefWithAttributesAttributes;
@property (strong, nonatomic) NSDictionary *wikitextRefSelfClosingAttributes;
@property (strong, nonatomic) NSDictionary *wikitextH2Attributes;
@property (strong, nonatomic) NSDictionary *wikitextH3Attributes;
@property (strong, nonatomic) NSDictionary *wikitextH4Attributes;
@property (strong, nonatomic) NSDictionary *wikitextH5Attributes;
@property (strong, nonatomic) NSDictionary *wikitextH6Attributes;
@property (strong, nonatomic) NSDictionary *wikitextListBulletAttributes;
@property (strong, nonatomic) NSDictionary *wikitextListNumberAttributes;

@end

@implementation NSMutableAttributedStringHelper

- (instancetype)initWithTheme:(WMFTheme *)theme andPreferredContentSizeCategory:(UIContentSizeCategory)preferredContentSizeCategory {
    self = [super init];
    if (self) {

        NSInteger standardSize;
        if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryExtraSmall]) {
            standardSize = 10;
        } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategorySmall]) {
            standardSize = 12;
        } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryMedium]) {
            standardSize = 14;
        } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryLarge]) {
            standardSize = 16;
        } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryExtraLarge]) {
            standardSize = 18;
        } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryExtraExtraLarge]) {
            standardSize = 20;
        } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge]) {
            standardSize = 22;
        } else {
            standardSize = 16;
        }

        _standardFont = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont systemFontOfSize:16]];
        _boldFontDescriptor = [_standardFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        _italicFontDescriptor = [_standardFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
        _boldItalicFontDescriptor = [_standardFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold];
        _boldFont = [UIFont fontWithDescriptor:_boldFontDescriptor size:_standardFont.pointSize];
        _italicFont = [UIFont fontWithDescriptor:_italicFontDescriptor size:_standardFont.pointSize];
        _boldItalicFont = [UIFont fontWithDescriptor:_boldItalicFontDescriptor size:_standardFont.pointSize];

        _h2Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 10]];
        _h3Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 8]];
        _h4Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 6]];
        _h5Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 4]];
        _h6Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 2]];

        _boldItalicRegexStr = @"('{5})([^']*(?:'(?!'''')[^']*)*)('{5})";
        _boldRegexStr = @"('{3})([^']*(?:'(?!'')[^']*)*)('{3})";

        // Explaining the most complicated example here, others (bold, italic, link) follow a similar pattern
        // ('{2})       - matches opening ''. Captures in group so it can be orangified.
        // (            - start of capturing group. The group that will be italisized.
        // [^']*        - matches any character that isn't a ' zero or more times
        // (?:          - beginning of non-capturing group
        // (?<!')'(?!') - matches any ' that are NOT followed or preceded by another ' (so single apostrophes or words like "don't" still get formatted
        // [^']*        - matches any character that isn't a ' zero or more times
        // )*           - end of non-capturing group, which can happen zero or more times (i.e. all single apostrophe logic)
        // )            - end of capturing group. End italisization
        // ('{2})       - matches ending ''. Captures in group so it can be orangified.

        _italicRegexStr = @"('{2})([^']*(?:(?<!')'(?!')[^']*)*)('{2})";
        _linkRegexStr = @"(\\[{2})[^\\[]*(?:\\[(?!\\[)[^'\\[]*)*(\\]{2})";
        _imageRegexStr = @"(\\[{2}File:)[^\\[]*(?:\\[(?!\\[)[^'\\[]*)*(\\]{2})";
        _sameLineTemplateRegexStr = @"\\{{2}.*\\}{2}";
        _singleClosingTemplateRegexStr = @"^\\}{2}$";

        _refRegexStr = @"(<ref>)\\s*.*?(<\\/ref>)";
        _refWithAttributesRegexStr = @"(<ref\\s+.+?>)\\s*.*?(<\\/ref>)";
        _refSelfClosingRegexStr = @"<ref\\s[^>]+?\\s*\\/>";

        _supRegexStr = @"(<sup>)\\s*.*?(<\\/sup>)";
        _subRegexStr = @"(<sub>)\\s*.*?(<\\/sub>)";
        _underlineRegexStr = @"(<u>)\\s*.*?(<\\/u>)";
        _strikethroughRegexStr = @"(<s>)\\s*.*?(<\\/s>)";

        _commentRegexStr = @"(<!--)\\s*.*?(-->)";

        _h2RegexStr = @"^(={2})([^=]*)(={2})(?!=)$";
        _h3RegexStr = @"^(={3})([^=]*)(={3})(?!=)$";
        _h4RegexStr = @"^(={4})([^=]*)(={4})(?!=)$";
        _h5RegexStr = @"^(={5})([^=]*)(={5})(?!=)$";
        _h6RegexStr = @"^(={6})([^=]*)(={6})(?!=)$";

        _listBulletRegexStr = @"^(\\*+)(.*)";
        _listNumberRegexStr = @"^(#+)(.*)";

        _boldItalicRegex = [NSRegularExpression regularExpressionWithPattern:_boldItalicRegexStr options:0 error:nil];
        _boldRegex = [NSRegularExpression regularExpressionWithPattern:_boldRegexStr options:0 error:nil];
        _italicRegex = [NSRegularExpression regularExpressionWithPattern:_italicRegexStr options:0 error:nil];
        _linkRegex = [NSRegularExpression regularExpressionWithPattern:_linkRegexStr options:0 error:nil];
        _imageRegex = [NSRegularExpression regularExpressionWithPattern:_imageRegexStr options:0 error:nil];
        _sameLineTemplateRegex = [NSRegularExpression regularExpressionWithPattern:_sameLineTemplateRegexStr options:0 error:nil];
        _singleClosingTemplateRegex = [NSRegularExpression regularExpressionWithPattern:_singleClosingTemplateRegexStr options:NSRegularExpressionAnchorsMatchLines error:nil];
        _refRegex = [NSRegularExpression regularExpressionWithPattern:_refRegexStr options:0 error:nil];
        _refWithAttributesRegex = [NSRegularExpression regularExpressionWithPattern:_refWithAttributesRegexStr options:0 error:nil];
        _refSelfClosingRegex = [NSRegularExpression regularExpressionWithPattern:_refSelfClosingRegexStr options:0 error:nil];
        _supRegex = [NSRegularExpression regularExpressionWithPattern:_supRegexStr options:0 error:nil];
        _subRegex = [NSRegularExpression regularExpressionWithPattern:_subRegexStr options:0 error:nil];

        _underlineRegex = [NSRegularExpression regularExpressionWithPattern:_underlineRegexStr options:0 error:nil];
        _strikethroughRegex = [NSRegularExpression regularExpressionWithPattern:_strikethroughRegexStr options:0 error:nil];

        _commentRegex = [NSRegularExpression regularExpressionWithPattern:_commentRegexStr options:0 error:nil];

        _listBulletRegex = [NSRegularExpression regularExpressionWithPattern:_listBulletRegexStr options:0 error:nil];
        _listNumberRegex = [NSRegularExpression regularExpressionWithPattern:_listNumberRegexStr options:0 error:nil];

        _h2Regex = [NSRegularExpression regularExpressionWithPattern:_h2RegexStr options:NSRegularExpressionAnchorsMatchLines error:nil];
        _h3Regex = [NSRegularExpression regularExpressionWithPattern:_h3RegexStr options:NSRegularExpressionAnchorsMatchLines error:nil];
        _h4Regex = [NSRegularExpression regularExpressionWithPattern:_h4RegexStr options:NSRegularExpressionAnchorsMatchLines error:nil];
        _h5Regex = [NSRegularExpression regularExpressionWithPattern:_h5RegexStr options:NSRegularExpressionAnchorsMatchLines error:nil];
        _h6Regex = [NSRegularExpression regularExpressionWithPattern:_h6RegexStr options:NSRegularExpressionAnchorsMatchLines error:nil];

        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:5];
        [paragraphStyle setLineHeightMultiple:1.1];

        _commonAttributes = @{
            NSFontAttributeName: _standardFont,
            NSParagraphStyleAttributeName: paragraphStyle,
            NSForegroundColorAttributeName: theme.colors.primaryText
        };

        _boldAttributes = @{
            NSFontAttributeName: _boldFont,
            kCustomAttributedStringKeyFontBold: [NSNumber numberWithBool:YES]
        };

        _italicAttributes = @{
            NSFontAttributeName: _italicFont,
            kCustomAttributedStringKeyFontItalic: [NSNumber numberWithBool:YES]
        };

        _boldItalicAttributes = @{
            NSFontAttributeName: _boldItalicFont,
            kCustomAttributedStringKeyFontBoldItalic: [NSNumber numberWithBool:YES]
        };

        _linkAttributes = @{
            NSForegroundColorAttributeName: theme.colors.nativeEditorLink,
            kCustomAttributedStringKeyColorLink: [NSNumber numberWithBool:YES]
        };

        _templateAttributes = @{
            NSForegroundColorAttributeName: theme.colors.nativeEditorTemplate,
            kCustomAttributedStringKeyColorTempate: [NSNumber numberWithBool:YES]
        };

        _htmlTagAttributes = @{
            NSForegroundColorAttributeName: theme.colors.nativeEditorHtmlTag,
            kCustomAttributedStringKeyColorHtmlTag: [NSNumber numberWithBool:YES]
        };

        _commentAttributes = @{
            NSForegroundColorAttributeName: theme.colors.nativeEditorComment,
            kCustomAttributedStringKeyColorComment: [NSNumber numberWithBool:YES]
        };

        _orangeFontAttributes = @{
            NSForegroundColorAttributeName: theme.colors.nativeEditorShorthand,
            kCustomAttributedStringKeyColorShorthand: [NSNumber numberWithBool:YES]
        };

        _h2FontAttributes = @{
            NSFontAttributeName: _h2Font,
        };

        _h3FontAttributes = @{
            NSFontAttributeName: _h3Font,
        };

        _h4FontAttributes = @{
            NSFontAttributeName: _h4Font,
        };

        _h5FontAttributes = @{
            NSFontAttributeName: _h5Font,
        };

        _h6FontAttributes = @{
            NSFontAttributeName: _h6Font,
        };

        _wikitextBoldAttributes = @{
            kCustomAttributedStringKeyWikitextBold: [NSNumber numberWithBool:YES]
        };

        _wikitextItalicAttributes = @{
            kCustomAttributedStringKeyWikitextItalic: [NSNumber numberWithBool:YES]
        };

        _wikitextBoldAndItalicAttributes = @{
            kCustomAttributedStringKeyWikitextBoldAndItalic: [NSNumber numberWithBool:YES]
        };

        _wikitextLinkAttributes = @{
            kCustomAttributedStringKeyWikitextLink: [NSNumber numberWithBool:YES]
        };

        _wikitextImageAttributes = @{
            kCustomAttributedStringKeyWikitextImage: [NSNumber numberWithBool:YES]
        };

        _wikitextTemplateAttributes = @{
            kCustomAttributedStringKeyWikitextTemplate: [NSNumber numberWithBool:YES]
        };

        _wikitextRefAttributes = @{
            kCustomAttributedStringKeyWikitextRef: [NSNumber numberWithBool:YES]
        };

        _wikitextSupAttributes = @{
            kCustomAttributedStringKeyWikitextSuperscript: [NSNumber numberWithBool:YES]
        };

        _wikitextSubAttributes = @{
            kCustomAttributedStringKeyWikitextSubscript: [NSNumber numberWithBool:YES]
        };

        _wikitextCommentAttributes = @{
            kCustomAttributedStringKeyWikitextComment: [NSNumber numberWithBool:YES]
        };

        _wikitextUnderlineAttributes = @{
            kCustomAttributedStringKeyWikitextUnderline: [NSNumber numberWithBool:YES]
        };

        _wikitextStrikethroughAttributes = @{
            kCustomAttributedStringKeyWikitextStrikethrough: [NSNumber numberWithBool:YES]
        };

        _wikitextRefWithAttributesAttributes = @{
            kCustomAttributedStringKeyWikitextRefWithAttributes: [NSNumber numberWithBool:YES]
        };

        _wikitextRefSelfClosingAttributes = @{
            kCustomAttributedStringKeyWikitextRefSelfClosing: [NSNumber numberWithBool:YES]
        };

        _wikitextH2Attributes = @{
            kCustomAttributedStringKeyWikitextH2: [NSNumber numberWithBool:YES]
        };

        _wikitextH3Attributes = @{
            kCustomAttributedStringKeyWikitextH3: [NSNumber numberWithBool:YES]
        };

        _wikitextH4Attributes = @{
            kCustomAttributedStringKeyWikitextH4: [NSNumber numberWithBool:YES]
        };

        _wikitextH5Attributes = @{
            kCustomAttributedStringKeyWikitextH5: [NSNumber numberWithBool:YES]
        };

        _wikitextH6Attributes = @{
            kCustomAttributedStringKeyWikitextH6: [NSNumber numberWithBool:YES]
        };

        _wikitextListBulletAttributes = @{
            kCustomAttributedStringKeyWikitextBullet: [NSNumber numberWithBool:YES]
        };

        _wikitextListNumberAttributes = @{
            kCustomAttributedStringKeyWikitextNumber: [NSNumber numberWithBool:YES]
        };
    }
    return self;
}

- (void)recalculateAttributesAfterThemeOrFontSizeChangeWithTheme:(WMFTheme *)theme andPreferredContentSizeCategory:(UIContentSizeCategory)preferredContentSizeCategory {

    NSInteger standardSize;
    if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryExtraSmall]) {
        standardSize = 10;
    } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategorySmall]) {
        standardSize = 12;
    } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryMedium]) {
        standardSize = 14;
    } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryLarge]) {
        standardSize = 16;
    } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryExtraLarge]) {
        standardSize = 18;
    } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryExtraExtraLarge]) {
        standardSize = 20;
    } else if ([preferredContentSizeCategory isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge]) {
        standardSize = 22;
    } else {
        standardSize = 16;
    }

    self.standardFont = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont systemFontOfSize:standardSize]];
    self.boldFontDescriptor = [self.standardFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    self.italicFontDescriptor = [self.standardFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    self.boldItalicFontDescriptor = [self.standardFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold];
    self.boldFont = [UIFont fontWithDescriptor:self.boldFontDescriptor size:self.standardFont.pointSize];
    self.italicFont = [UIFont fontWithDescriptor:self.italicFontDescriptor size:self.standardFont.pointSize];
    self.boldItalicFont = [UIFont fontWithDescriptor:self.boldItalicFontDescriptor size:self.standardFont.pointSize];

    self.h2Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 10]];
    self.h3Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 8]];
    self.h4Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 6]];
    self.h5Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 4]];
    self.h6Font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:[UIFont systemFontOfSize:standardSize + 2]];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:5];
    [paragraphStyle setLineHeightMultiple:1.1];

    self.commonAttributes = @{
        NSFontAttributeName: self.standardFont,
        NSParagraphStyleAttributeName: paragraphStyle,
        NSForegroundColorAttributeName: theme.colors.primaryText
    };

    self.boldAttributes = @{
        NSFontAttributeName: self.boldFont,
        kCustomAttributedStringKeyFontBold: [NSNumber numberWithBool:YES]
    };

    self.italicAttributes = @{
        NSFontAttributeName: self.italicFont,
        kCustomAttributedStringKeyFontItalic: [NSNumber numberWithBool:YES]
    };

    self.boldItalicAttributes = @{
        NSFontAttributeName: self.boldItalicFont,
        kCustomAttributedStringKeyFontBoldItalic: [NSNumber numberWithBool:YES]
    };

    self.linkAttributes = @{
        NSForegroundColorAttributeName: theme.colors.nativeEditorLink,
        kCustomAttributedStringKeyColorLink: [NSNumber numberWithBool:YES]
    };

    self.templateAttributes = @{
        NSForegroundColorAttributeName: theme.colors.nativeEditorTemplate,
        kCustomAttributedStringKeyColorTempate: [NSNumber numberWithBool:YES]
    };

    self.htmlTagAttributes = @{
        NSForegroundColorAttributeName: theme.colors.nativeEditorHtmlTag,
        kCustomAttributedStringKeyColorHtmlTag: [NSNumber numberWithBool:YES]
    };

    self.commentAttributes = @{
        NSForegroundColorAttributeName: theme.colors.nativeEditorComment,
        kCustomAttributedStringKeyColorComment: [NSNumber numberWithBool:YES]
    };

    self.orangeFontAttributes = @{
        NSForegroundColorAttributeName: theme.colors.nativeEditorShorthand,
        kCustomAttributedStringKeyColorShorthand: [NSNumber numberWithBool:YES]
    };

    self.h2FontAttributes = @{
        NSFontAttributeName: _h2Font,
        kCustomAttributedStringKeyFontH2: [NSNumber numberWithBool:YES]
    };

    self.h3FontAttributes = @{
        NSFontAttributeName: _h3Font,
        kCustomAttributedStringKeyFontH3: [NSNumber numberWithBool:YES]
    };

    self.h4FontAttributes = @{
        NSFontAttributeName: _h4Font,
        kCustomAttributedStringKeyFontH4: [NSNumber numberWithBool:YES]
    };

    self.h5FontAttributes = @{
        NSFontAttributeName: _h5Font,
        kCustomAttributedStringKeyFontH5: [NSNumber numberWithBool:YES]
    };

    self.h6FontAttributes = @{
        NSFontAttributeName: _h6Font,
        kCustomAttributedStringKeyFontH6: [NSNumber numberWithBool:YES]
    };
}

- (void)addWikitextSyntaxFormattingToNSMutableAttributedString:(NSMutableAttributedString *)mutAttributedString searchRange:(NSRange)searchRange theme:(WMFTheme *)theme {

    [mutAttributedString addAttributes:self.commonAttributes range:searchRange];

    [self.refRegex enumerateMatchesInString:mutAttributedString.string
                                    options:0
                                      range:searchRange
                                 usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                     NSRange matchRange = [result rangeAtIndex:0];
                                     NSRange openingRange = [result rangeAtIndex:1];
                                     NSRange closingRange = [result rangeAtIndex:2];

                                     if (matchRange.location != NSNotFound) {
                                         [mutAttributedString addAttributes:self.wikitextRefAttributes range:matchRange];
                                     }

                                     if (openingRange.location != NSNotFound) {
                                         [mutAttributedString addAttributes:self.htmlTagAttributes range:openingRange];
                                     }

                                     if (closingRange.location != NSNotFound) {
                                         [mutAttributedString addAttributes:self.htmlTagAttributes range:closingRange];
                                     }
                                 }];

    [self.refWithAttributesRegex enumerateMatchesInString:mutAttributedString.string
                                                  options:0
                                                    range:searchRange
                                               usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                                   NSRange matchRange = [result rangeAtIndex:0];

                                                   if (matchRange.location != NSNotFound) {
                                                       [mutAttributedString addAttributes:self.htmlTagAttributes range:matchRange];
                                                       [mutAttributedString addAttributes:self.wikitextRefWithAttributesAttributes range:matchRange];
                                                   }
                                               }];

    [self.refSelfClosingRegex enumerateMatchesInString:mutAttributedString.string
                                               options:0
                                                 range:searchRange
                                            usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                                NSRange matchRange = [result rangeAtIndex:0];

                                                if (matchRange.location != NSNotFound) {
                                                    [mutAttributedString addAttributes:self.htmlTagAttributes range:matchRange];
                                                    [mutAttributedString addAttributes:self.wikitextRefSelfClosingAttributes range:matchRange];
                                                }
                                            }];

    [self.sameLineTemplateRegex enumerateMatchesInString:mutAttributedString.string
                                                 options:0
                                                   range:searchRange
                                              usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                                  NSRange matchRange = [result rangeAtIndex:0];

                                                  if (matchRange.location != NSNotFound) {
                                                      [mutAttributedString addAttributes:self.templateAttributes range:matchRange];
                                                      [mutAttributedString addAttributes:self.wikitextTemplateAttributes range:matchRange];
                                                  }
                                              }];

    [self.singleClosingTemplateRegex enumerateMatchesInString:mutAttributedString.string
                                                      options:0
                                                        range:searchRange
                                                   usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                                       NSRange matchRange = [result rangeAtIndex:0];

                                                       if (matchRange.location != NSNotFound) {
                                                           [mutAttributedString addAttributes:self.templateAttributes range:matchRange];
                                                           [mutAttributedString addAttributes:self.wikitextTemplateAttributes range:matchRange];
                                                       }
                                                   }];

    // Test: temporarily replace same line template indicators with something else, then run multiline regex string
    //    NSMutableString *tempString = [[NSMutableString alloc] initWithString:mutAttributedString.string];
    //    for (NSValue *sameLineRange in sameLineRanges) {
    //        NSRange range = [sameLineRange rangeValue];
    //        [tempString replaceOccurrencesOfString:@"{{" withString:@"%%" options:0 range:range];
    //        [tempString replaceOccurrencesOfString:@"}}" withString:@"%%" options:0 range:range];
    //    }
    //
    //    NSRange fullRange = (NSRange){0, tempString.length};
    //    [self.multiLineTemplateRegex enumerateMatchesInString:tempString
    //                                    options:0
    //                                      range:fullRange
    //                                 usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
    //                                     NSRange matchRange = [result rangeAtIndex:0];
    //
    //                                     if (matchRange.location != NSNotFound) {
    //                                         [mutAttributedString addAttributes:self.templateAttributes range:matchRange];
    //                                         [mutAttributedString addAttributes:self.wikitextTemplateAttributes range:matchRange];
    //                                     }
    //                                 }];

    [self.supRegex enumerateMatchesInString:mutAttributedString.string
                                    options:0
                                      range:searchRange
                                 usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                     NSRange matchRange = [result rangeAtIndex:0];
                                     NSRange openingRange = [result rangeAtIndex:1];
                                     NSRange closingRange = [result rangeAtIndex:2];

                                     if (matchRange.location != NSNotFound) {
                                         [mutAttributedString addAttributes:self.wikitextSupAttributes range:matchRange];
                                     }

                                     if (openingRange.location != NSNotFound) {
                                         [mutAttributedString addAttributes:self.htmlTagAttributes range:openingRange];
                                     }

                                     if (closingRange.location != NSNotFound) {
                                         [mutAttributedString addAttributes:self.htmlTagAttributes range:closingRange];
                                     }
                                 }];

    [self.subRegex enumerateMatchesInString:mutAttributedString.string
                                    options:0
                                      range:searchRange
                                 usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                     NSRange matchRange = [result rangeAtIndex:0];
                                     NSRange openingRange = [result rangeAtIndex:1];
                                     NSRange closingRange = [result rangeAtIndex:2];

                                     if (matchRange.location != NSNotFound) {
                                         [mutAttributedString addAttributes:self.wikitextSubAttributes range:matchRange];
                                     }

                                     if (openingRange.location != NSNotFound) {
                                         [mutAttributedString addAttributes:self.htmlTagAttributes range:openingRange];
                                     }

                                     if (closingRange.location != NSNotFound) {
                                         [mutAttributedString addAttributes:self.htmlTagAttributes range:closingRange];
                                     }
                                 }];

    [self.underlineRegex enumerateMatchesInString:mutAttributedString.string
                                          options:0
                                            range:searchRange
                                       usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                           NSRange matchRange = [result rangeAtIndex:0];
                                           NSRange openingRange = [result rangeAtIndex:1];
                                           NSRange closingRange = [result rangeAtIndex:2];

                                           if (matchRange.location != NSNotFound) {
                                               [mutAttributedString addAttributes:self.wikitextUnderlineAttributes range:matchRange];
                                           }

                                           if (openingRange.location != NSNotFound) {
                                               [mutAttributedString addAttributes:self.htmlTagAttributes range:openingRange];
                                           }

                                           if (closingRange.location != NSNotFound) {
                                               [mutAttributedString addAttributes:self.htmlTagAttributes range:closingRange];
                                           }
                                       }];

    [self.strikethroughRegex enumerateMatchesInString:mutAttributedString.string
                                              options:0
                                                range:searchRange
                                           usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                               NSRange matchRange = [result rangeAtIndex:0];
                                               NSRange openingRange = [result rangeAtIndex:1];
                                               NSRange closingRange = [result rangeAtIndex:2];

                                               if (matchRange.location != NSNotFound) {
                                                   [mutAttributedString addAttributes:self.wikitextStrikethroughAttributes range:matchRange];
                                               }

                                               if (openingRange.location != NSNotFound) {
                                                   [mutAttributedString addAttributes:self.htmlTagAttributes range:openingRange];
                                               }

                                               if (closingRange.location != NSNotFound) {
                                                   [mutAttributedString addAttributes:self.htmlTagAttributes range:closingRange];
                                               }
                                           }];

    [self.commentRegex enumerateMatchesInString:mutAttributedString.string
                                        options:0
                                          range:searchRange
                                     usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                         NSRange matchRange = [result rangeAtIndex:0];
                                         NSRange openingRange = [result rangeAtIndex:1];
                                         NSRange closingRange = [result rangeAtIndex:2];

                                         if (matchRange.location != NSNotFound) {
                                             [mutAttributedString addAttributes:self.commentAttributes range:matchRange];
                                             [mutAttributedString addAttributes:self.wikitextCommentAttributes range:matchRange];
                                         }
                                     }];

    [self.italicRegex enumerateMatchesInString:mutAttributedString.string
                                       options:0
                                         range:searchRange
                                    usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                        NSRange openingRange = [result rangeAtIndex:1];
                                        NSRange textRange = [result rangeAtIndex:2];
                                        NSRange closingRange = [result rangeAtIndex:3];

                                        if (textRange.location != NSNotFound) {
                                            [mutAttributedString addAttributes:self.italicAttributes range:textRange];
                                            [mutAttributedString addAttributes:self.wikitextItalicAttributes range:textRange];
                                        }

                                        if (openingRange.location != NSNotFound) {
                                            [mutAttributedString addAttributes:self.orangeFontAttributes range:openingRange];
                                        }

                                        if (closingRange.location != NSNotFound) {
                                            [mutAttributedString addAttributes:self.orangeFontAttributes range:closingRange];
                                        }
                                    }];

    [self.boldRegex enumerateMatchesInString:mutAttributedString.string
                                     options:0
                                       range:searchRange
                                  usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                      NSRange fullMatch = [result rangeAtIndex:0];
                                      NSRange openingRange = [result rangeAtIndex:1];
                                      NSRange textRange = [result rangeAtIndex:2];
                                      NSRange closingRange = [result rangeAtIndex:3];

                                      if (textRange.location != NSNotFound) {

                                          // helps to undo attributes from italic above.
                                          [mutAttributedString removeAttribute:kCustomAttributedStringKeyWikitextItalic range:fullMatch];
                                          [mutAttributedString removeAttribute:kCustomAttributedStringKeyFontItalic range:fullMatch];

                                          [mutAttributedString addAttributes:self.boldAttributes range:textRange];
                                          [mutAttributedString addAttributes:self.wikitextBoldAttributes range:textRange];
                                      }

                                      if (openingRange.location != NSNotFound) {
                                          [mutAttributedString addAttributes:self.orangeFontAttributes range:openingRange];
                                      }

                                      if (closingRange.location != NSNotFound) {
                                          [mutAttributedString addAttributes:self.orangeFontAttributes range:closingRange];
                                      }
                                  }];

    [self.boldItalicRegex enumerateMatchesInString:mutAttributedString.string
                                           options:0
                                             range:searchRange
                                        usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                            NSRange fullMatch = [result rangeAtIndex:0];
                                            NSRange openingRange = [result rangeAtIndex:1];
                                            NSRange textRange = [result rangeAtIndex:2];
                                            NSRange closingRange = [result rangeAtIndex:3];

                                            if (textRange.location != NSNotFound) {

                                                // helps to undo attributes from bold and italic single regex above.
                                                //                                           [mutAttributedString removeAttribute:NSFontAttributeName range:fullMatch];
                                                //                                           [mutAttributedString removeAttribute:NSForegroundColorAttributeName range:fullMatch];
                                                [mutAttributedString removeAttribute:kCustomAttributedStringKeyWikitextBold range:fullMatch];
                                                [mutAttributedString removeAttribute:kCustomAttributedStringKeyWikitextItalic range:fullMatch];
                                                [mutAttributedString removeAttribute:kCustomAttributedStringKeyFontBold range:fullMatch];
                                                [mutAttributedString removeAttribute:kCustomAttributedStringKeyFontItalic range:fullMatch];

                                                [mutAttributedString addAttributes:self.boldItalicAttributes range:textRange];
                                                [mutAttributedString addAttributes:self.wikitextBoldAndItalicAttributes range:textRange];
                                            }

                                            if (openingRange.location != NSNotFound) {
                                                [mutAttributedString addAttributes:self.orangeFontAttributes range:openingRange];
                                            }

                                            if (closingRange.location != NSNotFound) {
                                                [mutAttributedString addAttributes:self.orangeFontAttributes range:closingRange];
                                            }
                                        }];

    [self.linkRegex enumerateMatchesInString:mutAttributedString.string
                                     options:0
                                       range:searchRange
                                  usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                      NSRange matchRange = [result rangeAtIndex:0];

                                      if (matchRange.location != NSNotFound) {
                                          [mutAttributedString addAttributes:self.linkAttributes range:matchRange];
                                          [mutAttributedString addAttributes:self.wikitextLinkAttributes range:matchRange];
                                      }
                                  }];

    // Undo any link hits from above regex
    [self.imageRegex enumerateMatchesInString:mutAttributedString.string
                                      options:0
                                        range:searchRange
                                   usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                       NSRange matchRange = [result rangeAtIndex:0];

                                       if (matchRange.location != NSNotFound) {
                                           [mutAttributedString removeAttribute:kCustomAttributedStringKeyWikitextLink range:matchRange];
                                           [mutAttributedString addAttributes:self.wikitextImageAttributes range:matchRange];
                                       }
                                   }];

    [self.h2Regex enumerateMatchesInString:mutAttributedString.string
                                   options:0
                                     range:searchRange
                                usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                    NSRange openingRange = [result rangeAtIndex:1];
                                    NSRange textRange = [result rangeAtIndex:2];
                                    NSRange closingRange = [result rangeAtIndex:3];

                                    if (textRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.h2FontAttributes range:textRange];
                                        [mutAttributedString addAttributes:self.wikitextH2Attributes range:textRange];
                                    }

                                    if (openingRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.orangeFontAttributes range:openingRange];
                                        [mutAttributedString addAttributes:self.h2FontAttributes range:openingRange];
                                    }

                                    if (closingRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.orangeFontAttributes range:closingRange];
                                        [mutAttributedString addAttributes:self.h2FontAttributes range:closingRange];
                                    }
                                }];

    [self.h3Regex enumerateMatchesInString:mutAttributedString.string
                                   options:0
                                     range:searchRange
                                usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                    NSRange openingRange = [result rangeAtIndex:1];
                                    NSRange textRange = [result rangeAtIndex:2];
                                    NSRange closingRange = [result rangeAtIndex:3];

                                    if (textRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.h5FontAttributes range:textRange];
                                        [mutAttributedString addAttributes:self.wikitextH3Attributes range:textRange];
                                    }

                                    if (openingRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.orangeFontAttributes range:openingRange];
                                        [mutAttributedString addAttributes:self.h3FontAttributes range:openingRange];
                                    }

                                    if (closingRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.orangeFontAttributes range:closingRange];
                                        [mutAttributedString addAttributes:self.h3FontAttributes range:closingRange];
                                    }
                                }];

    [self.h4Regex enumerateMatchesInString:mutAttributedString.string
                                   options:0
                                     range:searchRange
                                usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                    NSRange openingRange = [result rangeAtIndex:1];
                                    NSRange textRange = [result rangeAtIndex:2];
                                    NSRange closingRange = [result rangeAtIndex:3];

                                    if (textRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.h5FontAttributes range:textRange];
                                        [mutAttributedString addAttributes:self.wikitextH4Attributes range:textRange];
                                    }

                                    if (openingRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.orangeFontAttributes range:openingRange];
                                        [mutAttributedString addAttributes:self.h4FontAttributes range:openingRange];
                                    }

                                    if (closingRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.orangeFontAttributes range:closingRange];
                                        [mutAttributedString addAttributes:self.h4FontAttributes range:closingRange];
                                    }
                                }];

    [self.h5Regex enumerateMatchesInString:mutAttributedString.string
                                   options:0
                                     range:searchRange
                                usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                    NSRange openingRange = [result rangeAtIndex:1];
                                    NSRange textRange = [result rangeAtIndex:2];
                                    NSRange closingRange = [result rangeAtIndex:3];

                                    if (textRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.h5FontAttributes range:textRange];
                                        [mutAttributedString addAttributes:self.wikitextH5Attributes range:textRange];
                                    }

                                    if (openingRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.orangeFontAttributes range:openingRange];
                                        [mutAttributedString addAttributes:self.h5FontAttributes range:openingRange];
                                    }

                                    if (closingRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.orangeFontAttributes range:closingRange];
                                        [mutAttributedString addAttributes:self.h5FontAttributes range:closingRange];
                                    }
                                }];

    [self.h6Regex enumerateMatchesInString:mutAttributedString.string
                                   options:0
                                     range:searchRange
                                usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                    NSRange openingRange = [result rangeAtIndex:1];
                                    NSRange textRange = [result rangeAtIndex:2];
                                    NSRange closingRange = [result rangeAtIndex:3];

                                    if (textRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.h6FontAttributes range:textRange];
                                        [mutAttributedString addAttributes:self.wikitextH6Attributes range:textRange];
                                    }

                                    if (openingRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.orangeFontAttributes range:openingRange];
                                        [mutAttributedString addAttributes:self.h6FontAttributes range:openingRange];
                                    }

                                    if (closingRange.location != NSNotFound) {
                                        [mutAttributedString addAttributes:self.orangeFontAttributes range:closingRange];
                                        [mutAttributedString addAttributes:self.h6FontAttributes range:closingRange];
                                    }
                                }];

    [self.listBulletRegex enumerateMatchesInString:mutAttributedString.string
                                           options:0
                                             range:searchRange
                                        usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                            NSRange allRange = [result rangeAtIndex:0];
                                            NSRange bulletRange = [result rangeAtIndex:1];

                                            if (bulletRange.location != NSNotFound) {
                                                [mutAttributedString addAttributes:self.orangeFontAttributes range:bulletRange];
                                            }

                                            if (allRange.location != NSNotFound) {
                                                [mutAttributedString addAttributes:self.wikitextListBulletAttributes range:allRange];
                                            }
                                        }];

    [self.listNumberRegex enumerateMatchesInString:mutAttributedString.string
                                           options:0
                                             range:searchRange
                                        usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                            NSRange allRange = [result rangeAtIndex:0];
                                            NSRange bulletRange = [result rangeAtIndex:1];

                                            if (bulletRange.location != NSNotFound) {
                                                [mutAttributedString addAttributes:self.orangeFontAttributes range:bulletRange];
                                            }

                                            if (allRange.location != NSNotFound) {
                                                [mutAttributedString addAttributes:self.wikitextListNumberAttributes range:allRange];
                                            }
                                        }];
}

@end
