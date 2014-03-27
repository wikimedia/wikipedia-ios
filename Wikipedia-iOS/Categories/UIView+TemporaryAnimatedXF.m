//  Created by Monte Hurd on 3/26/14.

#import "UIView+TemporaryAnimatedXF.h"

@implementation UIView (TemporaryAnimatedXF)

-(void)animateAndRewindXF:(CATransform3D)xf afterDelay:(CGFloat)delay duration:(CGFloat)duration
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.fillMode = kCAFillModeForwards;
    animation.autoreverses = YES;
    animation.duration = duration;
    animation.removedOnCompletion = YES;
    animation.beginTime = CACurrentMediaTime() + delay;
    animation.toValue = [NSValue valueWithCATransform3D:xf];
    [self.layer addAnimation:animation forKey:nil];
}

@end
