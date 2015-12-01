//
//  NSString+WMFGlyphs.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/28/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, WMFGlyph) {
    WMF_GLYPH_W,
    WMF_GLYPH_SHARE,
    WMF_GLYPH_MAGNIFY,
    WMF_GLYPH_MAGNIFY_BOLD,
    WMF_GLYPH_FORWARD,
    WMF_GLYPH_BACKWARD,
    WMF_GLYPH_DOWN,
    WMF_GLYPH_HEART,
    WMF_GLYPH_HEART_OUTLINE,
    WMF_GLYPH_TOC_COLLAPSED,
    WMF_GLYPH_TOC_EXPANDED,
    WMF_GLYPH_STAR,
    WMF_GLYPH_STAR_OUTLINE,
    WMF_GLYPH_TICK,
    WMF_GLYPH_X,
    WMF_GLYPH_DICE,
    WMF_GLYPH_ENVELOPE,
    WMF_GLYPH_CARET_LEFT,
    WMF_GLYPH_TRASH,
    WMF_GLYPH_FLAG,
    WMF_GLYPH_USER_SMILE,
    WMF_GLYPH_USER_SLEEP,
    WMF_GLYPH_TRANSLATE,
    WMF_GLYPH_PENCIL,
    WMF_GLYPH_LINK,
    WMF_GLYPH_CC,
    WMF_GLYPH_X_CIRCLE,
    WMF_GLYPH_CITE,
    WMF_GLYPH_PUBLIC_DOMAIN,
    WMF_GLYPH_RELOAD
};

@interface NSString (WMFGlyphs)

+ (CGFloat)wmf_baselineOffsetToCenterGlyph:(WMFGlyph)glyph;

+ (NSString*)wmf_stringForGlyph:(WMFGlyph)glyph;

@end

@interface NSAttributedString (WMFGlyphs)

+ (NSAttributedString*)attributedStringForGlyph:(WMFGlyph)glyph color:(UIColor* __nullable)color;

+ (NSAttributedString*)attributedStringForGlyph:(WMFGlyph)glyph
                                       fontSize:(NSNumber* __nullable)fontSize
                                 baselineOffset:(NSNumber* __nullable)baselineOffset
                                          color:(UIColor* __nullable)color;

@end

NS_ASSUME_NONNULL_END
