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

+ (nullable NSString *)wmf_accessibilityLabelForButtonType:(WMFButtonType)type {
    switch (type) {
        case WMFButtonTypeX:
            return [WMFCommonStrings closeButtonAccessibilityLabel];
        case WMFButtonTypeCaretLeft:
            return [WMFCommonStrings accessibilityBackTitle];
        default:
            return nil;
    }
}

- (void)wmf_setButtonType:(WMFButtonType)type {
    [self setImage:[UIImage wmf_imageForType:type] forState:UIControlStateNormal];
    self.accessibilityLabel = [UIButton wmf_accessibilityLabelForButtonType:type];
}

@end

@implementation UIImage (WMFButton)

+ (nullable UIImage *)wmf_imageForType:(WMFButtonType)type {
    switch (type) {
        case WMFButtonTypeX:
            return [UIImage imageNamed:@"close"];
        case WMFButtonTypeCaretLeft:
            return [UIImage wmf_imageFlippedForRTLLayoutDirectionNamed:@"chevron-left"];
        default:
            return nil;
    }
}

@end
NS_ASSUME_NONNULL_END
