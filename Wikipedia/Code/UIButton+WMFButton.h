#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WMFButtonType) {
    WMFButtonTypeX,
    WMFButtonTypeCaretLeft
};

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (WMFButton)

+ (UIButton *)wmf_buttonType:(WMFButtonType)type target:(nullable id)target action:(nullable SEL)action;

- (void)wmf_setButtonType:(WMFButtonType)type;

@end

NS_ASSUME_NONNULL_END
