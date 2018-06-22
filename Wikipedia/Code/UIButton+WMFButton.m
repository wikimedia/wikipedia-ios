#import "UIButton+WMFButton.h"
#import "Wikipedia-Swift.h"
@import WMF.UIImage_WMFStyle;

NS_ASSUME_NONNULL_BEGIN

@implementation UIButton (WMFButton)

+ (UIButton *)wmf_buttonType:(WMFButtonType)type target:(nullable id)target action:(nullable SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = (CGRect){{0, 0}, {24, 40}};

    [button wmf_setButtonType:type];

    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (void)wmf_setButtonType:(WMFButtonType)type {
    switch (type) {
        case WMFButtonTypeX:
            [self setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
            self.accessibilityLabel = [WMFCommonStrings closeButtonAccessibilityLabel];
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
