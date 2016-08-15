#import "UIView+WMFWelcomeFadeInAndUp.h"

@implementation UIView (WMFWelcomeFadeInAndUp)

- (void)wmf_zeroLayerOpacity {
    self.layer.opacity = 0.0;
}

- (void)wmf_fadeInAndUpAfterDelay:(CGFloat)delay {
    self.layer.transform = CATransform3DMakeTranslation(0, 18, 0);
    [UIView animateWithDuration:0.4
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.layer.opacity = 1.0;
                       self.layer.transform = CATransform3DIdentity;
                     }
                     completion:nil];
}

@end
