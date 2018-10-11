@import UIKit;

typedef NS_ENUM(NSInteger, WMFButtonType) {
    WMFButtonTypeX,
    WMFButtonTypeCaretLeft
};

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (WMFButton)

+ (UIButton *)wmf_buttonType:(WMFButtonType)type target:(nullable id)target action:(nullable SEL)action;

+ (nullable NSString *)wmf_accessibilityLabelForButtonType:(WMFButtonType)type;

@end

@interface UIImage (WMFButton)

+ (nullable UIImage *)wmf_imageForType:(WMFButtonType)type;

@end

NS_ASSUME_NONNULL_END
