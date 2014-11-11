//  Created by Monte Hurd on 11/10/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIView+RoundCorners.h"

@implementation UIView (RoundCorners)

-(void)roundCorners:(UIRectCorner)corners toRadius:(float)radius
{   // Use for rounding *specific* corners of a UIView.
    // Based on http://stackoverflow.com/a/5826745/135557

    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect: self.bounds
                                                   byRoundingCorners: corners
                                                         cornerRadii: CGSizeMake(radius, radius)];
    // Create the shape layer and set its path
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;

    // Set the newly created shape layer as the mask for the image view's layer
    self.layer.mask = maskLayer;
}

@end
