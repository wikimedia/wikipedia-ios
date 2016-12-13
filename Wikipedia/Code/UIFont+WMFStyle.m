#import "UIFont+WMFStyle.h"

@implementation UIFont (WMF_Style)

+ (UIFont *)wmf_htmlBodyFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

+ (UIFont *)wmf_glyphFontOfSize:(CGFloat)fontSize;
{
    UIFont *font = [UIFont fontWithName:@"WikiFont-Glyphs" size:fontSize];

    NSAssert(font, @"Unable to load glyph font");

    return font;
}

- (instancetype)wmf_copyWithSizeScaledBy:(CGFloat)scalar {
    return [self fontWithSize:self.pointSize * scalar];
}

+ (instancetype)wmf_nearbyTitleFont {
    return [UIFont wmf_preferredFontForFontFamily:WMFFontFamilyGeorgia
                                    withTextStyle:UIFontTextStyleTitle2];
}

+ (instancetype)wmf_subtitle {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}

+ (instancetype)wmf_nearbyDistanceFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
}

@end
