//  Created by Monte Hurd on 2/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIFont+WMFStyle.h"
#import "Defines.h"

@implementation UIFont (WMF_Style)

+ (UIFont*)wmf_htmlBodyFont {
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

+ (UIFont*)wmf_glyphFontOfSize:(CGFloat)fontSize;
{
    UIFont* font = [UIFont fontWithName:@"WikiFont-Glyphs" size:fontSize];

    NSAssert(font, @"Unable to load glyph font");

    return font;
}

- (instancetype)wmf_copyWithSizeScaledBy:(CGFloat)scalar {
    return [self fontWithSize:self.pointSize * scalar];
}

- (instancetype)wmf_copyWithSizeScaledByMenuMultiplier {
    return [self wmf_copyWithSizeScaledBy:MENUS_SCALE_MULTIPLIER];
}

+ (instancetype)wmf_tableOfContentsHeaderFont {
    return [UIFont systemFontOfSize:12];
}

+ (instancetype)wmf_tableOfContentsSectionFont {
    static UIFont* f = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        f = [UIFont fontWithName:@"Georgia" size:22];
    });
    return f;
}

+ (instancetype)wmf_tableOfContentsSubsectionFont {
    return [UIFont systemFontOfSize:14];
}

+ (instancetype)wmf_nearbyTitleFont {
    return [UIFont fontWithName:@"Georgia" size:20.0];
}

+ (instancetype)wmf_nearbyDescriptionFont {
    return [UIFont systemFontOfSize:14.0f];
}

+ (instancetype)wmf_nearbyDistanceFont {
    return [UIFont systemFontOfSize:12.0f];
}

+ (instancetype)wmf_homeSectionHeaderFont {
    return [UIFont systemFontOfSize:16.0];
}

@end
