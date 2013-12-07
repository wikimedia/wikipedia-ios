//  Created by Monte Hurd on 12/9/13.

#import "UIWebView+Reveal.h"

@implementation UIWebView (Reveal)

- (void)fade
{
    self.alpha = 0.0f;
}

- (void)reveal
{
    if (self.alpha != 1.0f) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.18];
        //[UIView setAnimationDelay:0.3f];
        [self setAlpha:1.0f];
        [UIView commitAnimations];
    }
}

@end
