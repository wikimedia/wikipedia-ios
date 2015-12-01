//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIButton+WMFButton.h"
#import "UIControl+BlocksKit.h"
#import "UIFont+WMFStyle.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "WikipediaAppUtils.h"
#import "UIView+WMFRTLMirroring.h"
#import "NSString+WMFGlyphs.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIButton (WMFGlyph)

+ (UIButton*)wmf_buttonType:(WMFButtonType)type handler:(void (^ __nullable)(id sender))action {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = (CGRect){{0, 0}, {40, 40}};

    [button wmf_setButtonType:type];

    [button bk_addEventHandler:^(UIButton* sender){
        sender.highlighted = !sender.selected; // Prevent annoying flicker.
    } forControlEvents:UIControlEventTouchDown];

    [button bk_addEventHandler:^(UIButton* sender){
        sender.highlighted = !sender.selected;     // Prevent annoying flicker.
        float const horizontalScaleMultiplier = [sender xMirroringMultiplierForButtonType:type] * 1.25;
        CATransform3D scaleTransform = CATransform3DMakeScale(horizontalScaleMultiplier, 1.25, 1.0f);
        [sender animateAndRewindXF:scaleTransform afterDelay:0.0 duration:0.04f then:^{
            if (action) {
                action(sender);
            }
        }];
    }
              forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (void)wmf_setGlyphTitle:(WMFGlyph)glyph color:(UIColor* __nullable)color forState:(UIControlState)state {
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
            [self setImage:[UIImage imageNamed:@"toc"] forState:UIControlStateNormal];
            break;
        case WMFButtonTypeX:
            [self setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
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
            [self setImage:[UIImage imageNamed:@"save"] forState:UIControlStateNormal];
            [self setImage:[UIImage imageNamed:@"save-filled"] forState:UIControlStateSelected];
            break;
        case WMFButtonTypeBookmarkMini:
            [self setImage:[UIImage imageNamed:@"save-mini"] forState:UIControlStateNormal];
            [self setImage:[UIImage imageNamed:@"save-filled-mini"] forState:UIControlStateSelected];
            [self setTitle:MWLocalizedString(@"button-save-for-later", nil) forState:UIControlStateNormal];
            [self setTitle:MWLocalizedString(@"button-saved-for-later", nil) forState:UIControlStateSelected];
            break;
        case WMFButtonTypeClose:
            [self setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
            break;
        case WMFButtonTypeCloseMini:
            [self setImage:[UIImage imageNamed:@"close-mini"] forState:UIControlStateNormal];
            break;
        case WMFButtonTypeFeaturedMini:
            [self setImage:[UIImage imageNamed:@"featured-mini"] forState:UIControlStateNormal];
            break;
        case WMFButtonTypeNearbyMini:
            [self setImage:[UIImage imageNamed:@"nearby-mini"] forState:UIControlStateNormal];
            break;
        case WMFButtonTypeRecentMini:
            [self setImage:[UIImage imageNamed:@"recent-mini"] forState:UIControlStateNormal];
            break;
        case WMFButtonTypeShareMini:
            [self setImage:[UIImage imageNamed:@"share-mini"] forState:UIControlStateNormal];
            break;
        case WMFButtonTypeTrendingMini:
            [self setImage:[UIImage imageNamed:@"trending-mini"] forState:UIControlStateNormal];
            break;
        case WMFButtonTypeClearMini:
            [self setImage:[UIImage imageNamed:@"clear-mini"] forState:UIControlStateNormal];
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

NS_ASSUME_NONNULL_END
