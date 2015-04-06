//  Created by Monte Hurd on 3/29/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIWebView+HideScrollGradient.h"

@implementation UIWebView (HideScrollGradient)

- (void)hideScrollGradient {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        return;
    }
    for (UIView* view in self.scrollView.subviews.copy) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.hidden = YES;
        }
    }
}

@end
