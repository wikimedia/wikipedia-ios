#import <UIKit/UIKit.h>

@interface UIView (TemporaryAnimatedXF)

- (void)animateAndRewindXF:(CATransform3D)xf
                afterDelay:(CGFloat)delay
                  duration:(CGFloat)duration
                      then:(void (^)(void))block;

@end
