//  Created by Monte Hurd on 3/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!


#import <UIKit/UIKit.h>

@interface UIScrollView (WMFScrollsToTop)

/*
   Status bar taps only cause a scroll view to scroll to top if there is one
   and only one scroll view with "scrollsToTop" set to YES. This method
   ensures this scroll view's "scrollToTop" is the only one set to YES.
 */
- (void)wmf_shouldScrollToTopOnStatusBarTap:(BOOL)shouldScrollOnTap;

@end

@interface UIView (WMFScrollsToTop)

/**
 *  Disable scrolls to top on any sroll views in the hirarchy of the given view
 *
 */
- (void)wmf_recursivelyDisableScrollsToTop;

@end

