//
//  NSString+WMFGlyphs.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/28/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSString+WMFGlyphs.h"
#import "UIFont+WMFStyle.h"

@implementation NSString (WMFGlyphs)

+ (CGFloat)wmf_baselineOffsetToCenterGlyph:(WMFGlyph)glyph {
    switch (glyph) {
        case WMF_GLYPH_W:
            return 2.0;
        case WMF_GLYPH_SHARE:
            return 0.2;
        case WMF_GLYPH_TOC_COLLAPSED:
            return 2.0;
        case WMF_GLYPH_TOC_EXPANDED:
            return 2.0;
        case WMF_GLYPH_X:
            return 2.8;
        case WMF_GLYPH_TRANSLATE:
            return 1.4;
        case WMF_GLYPH_MAGNIFY:
            return 1.0;
        case WMF_GLYPH_PENCIL:
            return 2.4;

        default:
            return 1.2;
    }
}

+ (NSString*)wmf_stringForGlyph:(WMFGlyph)glyph {
    switch (glyph) {
        case WMF_GLYPH_W: return @"\ue950";
        case WMF_GLYPH_SHARE: return @"\ue951";
        case WMF_GLYPH_MAGNIFY: return @"\ue952";
        case WMF_GLYPH_MAGNIFY_BOLD: return @"\ue953";
        case WMF_GLYPH_FORWARD: return @"\ue954";
        case WMF_GLYPH_BACKWARD: return @"\ue955";
        case WMF_GLYPH_DOWN: return @"\ue956";
        case WMF_GLYPH_HEART: return @"\ue957";
        case WMF_GLYPH_HEART_OUTLINE: return @"\ue958";
        case WMF_GLYPH_TOC_COLLAPSED: return @"\ue959";
        case WMF_GLYPH_TOC_EXPANDED: return @"\ue95a";
        case WMF_GLYPH_STAR: return @"\ue95b";
        case WMF_GLYPH_STAR_OUTLINE: return @"\ue95c";
        case WMF_GLYPH_TICK: return @"\ue95d";
        case WMF_GLYPH_X: return @"\ue95e";
        case WMF_GLYPH_DICE: return @"\ue95f";
        case WMF_GLYPH_ENVELOPE: return @"\ue960";
        case WMF_GLYPH_CARET_LEFT: return @"\ue961";
        case WMF_GLYPH_TRASH: return @"\ue962";
        case WMF_GLYPH_FLAG: return @"\ue963";
        case WMF_GLYPH_USER_SMILE: return @"\ue964";
        case WMF_GLYPH_USER_SLEEP: return @"\ue965";
        case WMF_GLYPH_TRANSLATE: return @"\ue966";
        case WMF_GLYPH_PENCIL: return @"\ue967";
        case WMF_GLYPH_LINK: return @"\ue968";
        case WMF_GLYPH_CC: return @"\ue969";
        case WMF_GLYPH_X_CIRCLE: return @"\ue96a";
        case WMF_GLYPH_CITE: return @"\ue96b";
        case WMF_GLYPH_PUBLIC_DOMAIN: return @"\ue96c";
        case WMF_GLYPH_RELOAD: return @"\ue96d";
    }
}

@end

@implementation NSAttributedString (WMFGlyphs)

+ (NSAttributedString*)attributedStringForGlyph:(WMFGlyph)glyph color:(UIColor* __nullable)color {
    return [self attributedStringForGlyph:glyph fontSize:nil baselineOffset:nil color:color];
}

+ (NSAttributedString*)attributedStringForGlyph:(WMFGlyph)glyph
                                       fontSize:(NSNumber*)fontSize
                                 baselineOffset:(NSNumber*)baselineOffset
                                          color:(UIColor*)color {
    return [[NSAttributedString alloc] initWithString:[NSString wmf_stringForGlyph:glyph]
                                           attributes:@{
                NSFontAttributeName: [UIFont wmf_glyphFontOfSize:fontSize ? fontSize.unsignedIntegerValue : 32],
                NSBaselineOffsetAttributeName: baselineOffset ? : @([NSString wmf_baselineOffsetToCenterGlyph:glyph]),
                NSForegroundColorAttributeName: color ? : [UIColor blackColor]
            }];
}

@end
