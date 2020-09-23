#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "Wikipedia-Swift.h"

@import WMF.WMFLocalization;

@implementation UIBarButtonItem (WMFButtonConvenience)

+ (UIBarButtonItem *)wmf_buttonType:(WMFButtonType)type target:(nullable id)target action:(nullable SEL)action {
    UIImage *image = [UIImage wmf_imageForType:type];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:target action:action];
    item.accessibilityLabel = [UIButton wmf_accessibilityLabelForButtonType:type];
    return item;
}

- (nullable UIButton *)wmf_UIButton {
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
