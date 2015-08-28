//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

#import "NSString+WMFGlyphs.h"

typedef NS_ENUM (NSInteger, WMFButtonType) {
    WMFButtonTypeW,
    WMFButtonTypeShare,
    WMFButtonTypeForward,
    WMFButtonTypeBackward,
    WMFButtonTypeHeart,
    WMFButtonTypeTableOfContents,
    WMFButtonTypeX,
    WMFButtonTypeXWhite,
    WMFButtonTypeTrash,
    WMFButtonTypeTranslate,
    WMFButtonTypeMagnify,
    WMFButtonTypeReload,
    WMFButtonTypeCaretLeft,
    WMFButtonTypePencil,
    WMFButtonTypeBookmark
};

@interface UIButton (WMFGlyph)

+ (UIButton*)wmf_buttonType:(WMFButtonType)type
                    handler:(void (^)(id sender))action;

- (void)wmf_setButtonType:(WMFButtonType)type;

- (void)wmf_setGlyphTitle:(WMFGlyph)glyph color:(UIColor*)color forState:(UIControlState)state;

@end