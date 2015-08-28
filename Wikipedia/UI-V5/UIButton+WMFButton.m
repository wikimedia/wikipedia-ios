//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIButton+WMFButton.h"
#import "UIControl+BlocksKit.h"
#import "UIFont+WMFStyle.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "WikipediaAppUtils.h"
#import "UIView+WMFRTLMirroring.h"
#import "NSString+WMFGlyphs.h"

@implementation UIButton (WMFGlyph)

+ (UIButton*)wmf_buttonType:(WMFButtonType)type handler:(void (^)(id sender))action {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = (CGRect){{0, 0}, {40, 40}};

    [button wmf_setButtonType:type];

    [button bk_addEventHandler:^(UIButton* sender){
        sender.highlighted = !sender.selected; // Prevent annoying flicker.
    } forControlEvents:UIControlEventTouchDown];

    [button bk_addEventHandler:^(UIButton* sender){
        sender.highlighted = !sender.selected; // Prevent annoying flicker.
        [sender animateAndRewindXF:CATransform3DMakeScale([sender xMirroringMultiplierForButtonType:type] * 1.25, 1.25, 1.0f)
                        afterDelay:0.0
                          duration:0.04f
                              then:^{
            if (action) {
                action(sender);
            }
        }];
    } forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (void)wmf_setGlyphTitle:(WMFGlyph)glyph color:(UIColor*)color forState:(UIControlState)state {
    [self setAttributedTitle:[NSAttributedString attributedStringForGlyph:glyph color:color]
                    forState:state];
}

- (void)wmf_setButtonType:(WMFButtonType)type {
    [self mirrorIfNecessaryForType:type];

    switch (type) {
        case WMFButtonTypeW:
            [self wmf_setGlyphTitle:WMF_GLYPH_W color:nil forState:UIControlStateNormal];
            break;
        case WMFButtonTypeShare:
            [self wmf_setGlyphTitle:WMF_GLYPH_SHARE color:nil forState:UIControlStateNormal];
            break;
        case WMFButtonTypeForward:
            [self wmf_setGlyphTitle:WMF_GLYPH_FORWARD color:nil forState:UIControlStateNormal];
            [self wmf_setGlyphTitle:WMF_GLYPH_FORWARD color:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            break;
        case WMFButtonTypeBackward:
            [self wmf_setGlyphTitle:WMF_GLYPH_BACKWARD color:nil forState:UIControlStateNormal];
            [self wmf_setGlyphTitle:WMF_GLYPH_BACKWARD color:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            break;
        case WMFButtonTypeHeart:
            [self wmf_setGlyphTitle:WMF_GLYPH_HEART_OUTLINE color:nil forState:UIControlStateNormal];
            [self wmf_setGlyphTitle:WMF_GLYPH_HEART color:[UIColor redColor] forState:UIControlStateSelected];
            break;
        case WMFButtonTypeTableOfContents:
            [self wmf_setGlyphTitle:WMF_GLYPH_TOC_COLLAPSED color:nil forState:UIControlStateNormal];
            [self wmf_setGlyphTitle:WMF_GLYPH_TOC_COLLAPSED color:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            [self wmf_setGlyphTitle:WMF_GLYPH_TOC_EXPANDED color:nil forState:UIControlStateSelected];
            break;
        case WMFButtonTypeX:
            [self wmf_setGlyphTitle:WMF_GLYPH_X color:nil forState:UIControlStateNormal];
            break;
        case WMFButtonTypeXWhite:
            [self wmf_setGlyphTitle:WMF_GLYPH_X color:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case WMFButtonTypeTrash:
            [self wmf_setGlyphTitle:WMF_GLYPH_TRASH color:nil forState:UIControlStateNormal];
            [self wmf_setGlyphTitle:WMF_GLYPH_TRASH color:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            break;
        case WMFButtonTypeTranslate:
            [self wmf_setGlyphTitle:WMF_GLYPH_TRANSLATE color:nil forState:UIControlStateNormal];
            [self wmf_setGlyphTitle:WMF_GLYPH_TRANSLATE color:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            break;
        case WMFButtonTypeMagnify:
            [self wmf_setGlyphTitle:WMF_GLYPH_MAGNIFY color:nil forState:UIControlStateNormal];
            break;
        case WMFButtonTypeReload:
            [self wmf_setGlyphTitle:WMF_GLYPH_RELOAD color:nil forState:UIControlStateNormal];
            [self wmf_setGlyphTitle:WMF_GLYPH_RELOAD color:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            break;
        case WMFButtonTypeCaretLeft:
            [self wmf_setGlyphTitle:WMF_GLYPH_CARET_LEFT color:nil forState:UIControlStateNormal];
            break;
        case WMFButtonTypePencil:
            [self wmf_setGlyphTitle:WMF_GLYPH_PENCIL color:nil forState:UIControlStateNormal];
            [self wmf_setGlyphTitle:WMF_GLYPH_PENCIL color:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            break;
        case WMFButtonTypeBookmark:
            [self setImage:[UIImage imageNamed:@"unsaved"] forState:UIControlStateNormal];
            [self setImage:[UIImage imageNamed:@"saved"] forState:UIControlStateSelected];
            break;
        default:
            break;
    }
}

- (void)mirrorIfNecessaryForType:(WMFButtonType)type {
    self.transform = CGAffineTransformMakeScale(1.0* [self xMirroringMultiplierForButtonType:type], 1.0);
}

- (CGFloat)xMirroringMultiplierForButtonType:(WMFButtonType)type {
    if (![WikipediaAppUtils isDeviceLanguageRTL] || ![UIView wmf_shouldMirrorIfDeviceLanguageRTL]) {
        return 1.0;
    }
    return [self shouldMirrorButtonType:type] ? 1.0 : -1.0;
}

- (BOOL)shouldMirrorButtonType:(WMFButtonType)type {
    switch (type) {
        case WMFButtonTypeW:
        case WMFButtonTypeX:
        case WMFButtonTypeXWhite:
        case WMFButtonTypeTranslate:
        case WMFButtonTypeMagnify:
        case WMFButtonTypeReload:
        case WMFButtonTypePencil:
            return NO;
            break;
        default:
            return YES;
    }
}

@end
