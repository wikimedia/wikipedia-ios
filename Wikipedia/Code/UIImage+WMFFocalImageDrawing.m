//  Created by Monte Hurd on 3/12/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIImage+WMFFocalImageDrawing.h"

@implementation UIImage (WMFFocalImageDrawing)

- (void)wmf_drawInRect:(CGRect)rect
           focalBounds:(CGRect)focalBounds
        focalHighlight:(BOOL)focalHighlight
             blendMode:(CGBlendMode)blendMode
                 alpha:(CGFloat)alpha {
    if ((self.size.width == 0) || (self.size.height == 0)) {
        return;
    }

    // Aspect fill.
    float xScale = rect.size.width / self.size.width;
    float yScale = rect.size.height / self.size.height;
    float scale  = MAX(xScale, yScale);
    CGSize size  = CGSizeMake(self.size.width * scale, self.size.height * scale);

    // Align top.
    CGRect r = (CGRect){{0, 0}, size};

    // Center horizontally.
    CGFloat m1     = CGRectGetMidX(r);
    CGFloat m2     = CGRectGetMidX(rect);
    CGFloat offset = (m2 - m1);
    r = CGRectOffset(r, offset, 0.0);

    // Figure out bottom overlap so we can know how much we can move the image up.
    CGFloat bottomOverlap = r.size.height - rect.size.height;
    if (bottomOverlap > 0.0) {
        if (!CGRectIsEmpty(focalBounds)) {
            // Move image up to vertically center focal bounds (as much as possible).
            CGFloat yMidSelf        = CGRectGetMidY(rect);
            CGFloat yMidFocalBounds = CGRectGetMidY(focalBounds) * scale;
            CGFloat yShift          = fminf(yMidFocalBounds - yMidSelf, bottomOverlap);
            if (yShift > 0) {
                r = CGRectOffset(r, 0.0, -yShift);
            }
        } else {
            // If no focalBounds, move the image up a bit, if possible.
            CGFloat quarterOverlap = (bottomOverlap * 0.25);
            r = CGRectOffset(r, 0.0, -quarterOverlap);
        }
    }

    [self drawInRect:r blendMode:blendMode alpha:alpha];

    // Draw a box over the focal bounds.
    if (focalHighlight) {
        CGRect scaledfocalBounds =
            CGRectMake(
                (focalBounds.origin.x * scale) + r.origin.x,
                (focalBounds.origin.y * scale) + r.origin.y,
                focalBounds.size.width * scale,
                focalBounds.size.height * scale
                );
        [self fillFocalBounds:scaledfocalBounds];
    }
}

- (void)fillFocalBounds:(CGRect)bounds {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context       = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 0.0, 1.0, 0.0, 0.3);
    CGContextFillRect(context, bounds);
    CGColorSpaceRelease(colorSpace);
}

@end
