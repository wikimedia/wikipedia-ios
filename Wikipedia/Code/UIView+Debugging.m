#import "UIView+Debugging.h"

@implementation UIView (Debugging)

- (void)randomlyColorSubviews {
    // Add borders and random background colors to view and its subviews
    // Makes debugging autolayout easier
    float (^color)() = ^float() {
        return (float)arc4random_uniform(100) / 100.0f;
    };
    for (UIView *subView in self.subviews.copy) {
        subView.layer.borderWidth = 1.0f;
        subView.layer.borderColor = [UIColor colorWithWhite:0.0f alpha:0.5f].CGColor;
        subView.layer.backgroundColor = [UIColor colorWithRed:color()
                                                        green:color()
                                                         blue:color()
                                                        alpha:0.5]
                                            .CGColor;
        [subView randomlyColorSubviews];
    }
}

@end
