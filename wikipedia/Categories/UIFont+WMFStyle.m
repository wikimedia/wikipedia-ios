//  Created by Monte Hurd on 2/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIFont+WMFStyle.h"

@implementation UIFont (WMF_Style)

+(UIFont *)wmf_glyphFontOfSize:(CGFloat)fontSize;
{
    UIFont *font = [UIFont fontWithName:@"WikiFont-Glyphs" size:fontSize];

    NSAssert(font, @"Unable to load glyph font");

    return font;
}

@end
