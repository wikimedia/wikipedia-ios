//  Created by Monte Hurd on 3/29/14.

#import "UIWebView+HideScrollGradient.h"

@implementation UIWebView (HideScrollGradient)

-(void)hideScrollGradient
{
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) return;
    for (UIView *view in self.scrollView.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.hidden = YES;
        }
    }
}

@end
