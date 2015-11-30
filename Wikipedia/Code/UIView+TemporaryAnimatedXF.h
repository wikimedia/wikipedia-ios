//  Created by Monte Hurd on 3/26/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIView (TemporaryAnimatedXF)

- (void)animateAndRewindXF:(CATransform3D)xf
                afterDelay:(CGFloat)delay
                  duration:(CGFloat)duration
                      then:(void (^)(void))block;

@end
