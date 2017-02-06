#import "UIButton+WMFButton.h"
#import "UIFont+WMFStyle.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "UIImage+WMFStyle.h"
@import BlocksKitUIKitExtensions;

NS_ASSUME_NONNULL_BEGIN

@implementation UIButton (WMFButton)

+ (UIButton *)wmf_buttonType:(WMFButtonType)type handler:(void (^__nullable)(id sender))action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = (CGRect){{0, 0}, {24, 40}};

    [button wmf_setButtonType:type];

    [button bk_addEventHandler:^(UIButton *sender) {
        sender.highlighted = !sender.selected; // Prevent annoying flicker.
    }
              forControlEvents:UIControlEventTouchDown];

    [button bk_addEventHandler:^(UIButton *sender) {
        sender.highlighted = !sender.selected; // Prevent annoying flicker.
        CATransform3D scaleTransform = CATransform3DMakeScale(1.25, 1.25, 1.0f);
        [sender animateAndRewindXF:scaleTransform
                        afterDelay:0.0
                          duration:0.04f
                              then:^{
                                  if (action) {
                                      action(sender);
                                  }
                              }];
    }
              forControlEvents:UIControlEventTouchUpInside];

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
        default:
            break;
    }
}

@end

NS_ASSUME_NONNULL_END
