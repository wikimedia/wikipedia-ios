//  Created by Monte Hurd on 3/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIScrollView+WMFScrollsToTop.h"

@implementation UIScrollView (WMFScrollsToTop)

- (void)wmf_shouldScrollToTopOnStatusBarTap:(BOOL)shouldScrollOnTap {
    if (shouldScrollOnTap) {
        UIViewController* rootViewController =
            (UIViewController*)[[[UIApplication sharedApplication] delegate] window].rootViewController;
        [rootViewController.view.window wmf_recursivelyDisableScrollsToTop];
    }
    self.scrollsToTop = shouldScrollOnTap;
}

@end


@implementation UIView (WMFScrollsToTop)

- (void)wmf_recursivelyDisableScrollsToTop {
    for (UIView* subview in [self subviews]) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)subview;
            scrollView.scrollsToTop = NO;
        }
        [subview wmf_recursivelyDisableScrollsToTop];
    }
}

@end
