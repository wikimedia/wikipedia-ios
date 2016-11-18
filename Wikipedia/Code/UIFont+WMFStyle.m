#import "UIFont+WMFStyle.h"
#import "Defines.h"

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

- (instancetype)wmf_copyWithSizeScaledByMenuMultiplier {
    return [self wmf_copyWithSizeScaledBy:MENUS_SCALE_MULTIPLIER];
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
    return [UIFont fontWithName:@"Georgia" size:20.0];
}

+ (instancetype)wmf_subtitle {
    return [UIFont systemFontOfSize:14.0f];
}

+ (instancetype)wmf_nearbyDistanceFont {
    return [UIFont systemFontOfSize:12.0f];
}

@end
