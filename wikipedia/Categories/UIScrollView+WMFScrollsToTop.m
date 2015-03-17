//  Created by Monte Hurd on 3/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIScrollView+WMFScrollsToTop.h"

@implementation UIScrollView (WMFScrollsToTop)

- (void)wmf_shouldScrollToTopOnStatusBarTap:(BOOL)shouldScrollOnTap {
    if (shouldScrollOnTap) {
        UIViewController* rootViewController =
            (UIViewController*)[[[UIApplication sharedApplication] delegate] window].rootViewController;
        [self recursivelyDisableScrollsToTop:rootViewController.view];
    }
    self.scrollsToTop = shouldScrollOnTap;
}

- (void)recursivelyDisableScrollsToTop:(UIView*)view {
    for (UIView* subview in [view subviews]) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)subview;
            if ([scrollView scrollsToTop]) {
                scrollView.scrollsToTop = NO;
            }
        }
        [self recursivelyDisableScrollsToTop:subview];
    }
}

@end
