#import "UIView+TemporaryAnimatedXF.h"

@implementation UIView (TemporaryAnimatedXF)

- (void)animateAndRewindXF:(CATransform3D)xf
                afterDelay:(CGFloat)delay
                  duration:(CGFloat)duration
                      then:(void (^)(void))block {
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration];

    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.fillMode            = kCAFillModeForwards;
    animation.autoreverses        = YES;
    animation.removedOnCompletion = YES;
    animation.beginTime           = CACurrentMediaTime() + delay;
    animation.toValue             = [NSValue valueWithCATransform3D:xf];

    [CATransaction setCompletionBlock:block];

    [self.layer addAnimation:animation forKey:nil];

    [CATransaction commit];
}

@end
