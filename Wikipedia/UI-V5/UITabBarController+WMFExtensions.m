
#import "UITabBarController+WMFExtensions.h"

@implementation UITabBarController (WMFExtensions)

- (void)wmf_setTabBarVisible:(BOOL)visible animated:(BOOL)animated completion:(dispatch_block_t)completion {
    // bail if the current state matches the desired state
    if ([self wmf_tabBarIsVisible] == visible) {
        if (completion) {
            completion();
        }
        return;
    }
    ;

    // get a frame calculation ready
    CGRect frame    = self.tabBar.frame;
    CGFloat height  = frame.size.height;
    CGFloat offsetY = (visible) ? -height : height;

    // zero duration means no animation
    CGFloat duration = (animated) ? 0.2 : 0.0;

    [UIView animateWithDuration:duration animations:^{
        self.tabBar.frame = CGRectOffset(frame, 0, offsetY);
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

// know the current state
- (BOOL)wmf_tabBarIsVisible {
    return self.tabBar.frame.origin.y < CGRectGetMaxY(self.view.frame);
}

@end
