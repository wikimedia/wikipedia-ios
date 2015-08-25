//
//  UIView+WMFShadow.m
//
//
//  Created by Corey Floyd on 8/25/15.
//
//

#import "UIView+WMFShadow.h"

@implementation UIView (WMFShadow)

- (void)wmf_setupShadow {
    self.clipsToBounds       = NO;
    self.layer.shadowColor   = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.15;
    self.layer.shadowRadius  = 3.0;
    self.layer.shadowOffset  = CGSizeZero;
    [self wmf_updateShadowPathBasedOnBounds];
}

- (void)wmf_updateShadowPathBasedOnBounds {
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:CGRectInset(self.bounds, -1.0, -1.0)].CGPath;
}

@end
