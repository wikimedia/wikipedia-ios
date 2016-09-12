#import "UIView+WMFRoundCorners.h"

@implementation UIView (WMF_RoundCorners)

- (void)wmf_makeCircular {
    self.layer.cornerRadius = self.frame.size.width / 2.f;
}

- (void)wmf_roundCorners:(UIRectCorner)corners toRadius:(float)radius {
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                   byRoundingCorners:corners
                                                         cornerRadii:CGSizeMake(radius, radius)];
    // Create the shape layer and set its path
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;

    // Set the newly created shape layer as the mask for the image view's layer
    self.layer.mask = maskLayer;
}

@end
