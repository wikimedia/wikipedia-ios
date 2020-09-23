#import "UIButton+WMFButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIBarButtonItem (WMFButtonConvenience)

// Returns bar button item with our UIButton as its customView.
+ (UIBarButtonItem *)wmf_buttonType:(WMFButtonType)type target:(nullable id)target action:(nullable SEL)action;

// If self.customView is UIButton return it else return nil.
- (nullable UIButton *)wmf_UIButton;

+ (UIBarButtonItem *)wmf_barButtonItemOfFixedWidth:(CGFloat)width;

+ (UIBarButtonItem *)flexibleSpaceToolbarItem;

@end

NS_ASSUME_NONNULL_END
