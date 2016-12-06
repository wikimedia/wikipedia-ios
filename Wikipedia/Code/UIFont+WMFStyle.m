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

+ (instancetype)wmf_tableOfContentsSectionFont {
    static UIFont *f = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        f = [UIFont fontWithName:@"Georgia" size:18];
    });
    return f;
}

+ (instancetype)wmf_tableOfContentsSubsectionFont {
    return [UIFont systemFontOfSize:14];
}

+ (instancetype)wmf_nearbyTitleFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

+ (instancetype)wmf_subtitle {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}

+ (instancetype)wmf_nearbyDistanceFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
}

@end
