//  Created by Monte Hurd on 7/30/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ReferenceGradientView.h"

@implementation ReferenceGradientView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event {
    // Allow side-swipes to fall through to the references web view, but not
    // if a sub view with userInteractionEnabled YES was tapped.
    // See: http://stackoverflow.com/a/12355957
    for (UIView* view in self.subviews) {
        if (view.userInteractionEnabled) {
            if (CGRectContainsPoint(view.frame, point)) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGFloat topHalfAlpha = 0.88;

    // Make the gradient begin just below the vertical center.
    CGFloat gradientTop = CGRectGetMidY(rect) + 10;

    // Draw opaque black in top half of rect.
    CGRect topHalfRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, gradientTop);
    CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, topHalfAlpha);
    CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, topHalfAlpha);
    CGContextFillRect(ctx, topHalfRect);

    // Draw black to transparent gradient from middle to bottom of rect.
    // Gradient drawing based on: http://stackoverflow.com/a/422208
    CGGradientRef gradient;
    CGColorSpaceRef rgbSpace;
    size_t locationCount       = 2;
    CGFloat locations[2]       = { 0.0, 1.0 };
    CGFloat colorComponents[8] = {
        0.0, 0.0, 0.0, topHalfAlpha,    // starting color
        0.0, 0.0, 0.0, 0.0              // ending color
    };

    rgbSpace = CGColorSpaceCreateDeviceRGB();
    gradient = CGGradientCreateWithColorComponents(rgbSpace, colorComponents, locations, locationCount);

    //CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
    CGPoint midCenter    = CGPointMake(CGRectGetMidX(rect), gradientTop);
    CGPoint bottomCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGContextDrawLinearGradient(ctx, gradient, midCenter, bottomCenter, 0);

    CGGradientRelease(gradient);
    CGColorSpaceRelease(rgbSpace);
}

@end
