#import "UIBarButtonItem+WMFButtonConvenience.h"
@import WMF.WMFLocalization;

@implementation UIBarButtonItem (WMFButtonConvenience)

+ (UIBarButtonItem *)wmf_buttonType:(WMFButtonType)type target:(nullable id)target action:(nullable SEL)action {
    UIButton *button = [UIButton wmf_buttonType:type target:target action:action];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    item.width = button.intrinsicContentSize.width;
    return item;
}

- (UIButton *)wmf_UIButton {
    return [self.customView isKindOfClass:[UIButton class]] ? (UIButton *)self.customView : nil;
}

+ (UIBarButtonItem *)wmf_barButtonItemOfFixedWidth:(CGFloat)width {
    UIBarButtonItem *item =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                      target:nil
                                                      action:nil];
    item.width = width;
    return item;
}

+ (UIBarButtonItem *)flexibleSpaceToolbarItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                         target:nil
                                                         action:NULL];
}

@end
