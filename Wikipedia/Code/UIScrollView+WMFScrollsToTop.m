#import "UIScrollView+WMFScrollsToTop.h"

@implementation UIScrollView (WMFScrollsToTop)

- (void)wmf_shouldScrollToTopOnStatusBarTap:(BOOL)shouldScrollOnTap {
    if (shouldScrollOnTap) {
        UIViewController *rootViewController =
            (UIViewController *)[[[UIApplication sharedApplication] delegate] window].rootViewController;
        [rootViewController.view.window wmf_recursivelyEnableScrollsToTop];
    }
    self.scrollsToTop = shouldScrollOnTap;
}

@end

@implementation UIView (WMFScrollsToTop)

- (void)wmf_recursivelyEnableScrollsToTop {
    for (UIView *subview in [self subviews]) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)subview;
            scrollView.scrollsToTop = YES;
        }
        [subview wmf_recursivelyEnableScrollsToTop];
    }
}

@end
