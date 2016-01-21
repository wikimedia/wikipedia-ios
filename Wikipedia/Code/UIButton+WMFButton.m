//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIButton+WMFButton.h"
#import "UIControl+BlocksKit.h"
#import "UIFont+WMFStyle.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "WikipediaAppUtils.h"
#import "UIImage+WMFStyle.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIButton (WMFButton)

+ (UIButton*)wmf_buttonType:(WMFButtonType)type handler:(void (^ __nullable)(id sender))action {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = (CGRect){{0, 0}, {40, 40}};

    [button wmf_setButtonType:type];

    [button bk_addEventHandler:^(UIButton* sender){
        sender.highlighted = !sender.selected; // Prevent annoying flicker.
    } forControlEvents:UIControlEventTouchDown];

    [button bk_addEventHandler:^(UIButton* sender){
        sender.highlighted = !sender.selected;     // Prevent annoying flicker.
        CATransform3D scaleTransform = CATransform3DMakeScale(1.25, 1.25, 1.0f);
        [sender animateAndRewindXF:scaleTransform afterDelay:0.0 duration:0.04f then:^{
            if (action) {
                action(sender);
            }
        }];
    } forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (void)wmf_setButtonType:(WMFButtonType)type {
    switch (type) {
        case WMFButtonTypeX:
            [self setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
            break;
        case WMFButtonTypeCaretLeft:
            [self setImage:[UIImage wmf_imageFlippedForRTLLayoutDirectionNamed:@"chevron-left"] forState:UIControlStateNormal];
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
        case WMFButtonTypeClearMini:
            [self setImage:[UIImage imageNamed:@"clear-mini"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

@end

NS_ASSUME_NONNULL_END
