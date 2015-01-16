

#import "WMFShareCardImageContainer.h"
#import "FocalImage.h"


@implementation WMFShareCardImageContainer

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawGradientBackground];
    [self.image drawInRect: rect
               focalBounds: [self.image getFaceBounds]
            focalHighlight: NO
                 blendMode: kCGBlendModeMultiply
                     alpha: 1.0];
}

// TODO: in follow-up patch, factor drawGradientBackground from
// LeadImageContainer so that it is more generalizable for setting
// gradient segments.
-(void)drawGradientBackground
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    void (^drawGradient)(CGFloat, CGFloat, CGRect) = ^void(CGFloat upperAlpha, CGFloat bottomAlpha, CGRect rect) {
        CGFloat locations[] = {
            0.0,  // Upper color stop.
            1.0   // Bottom color stop.
        };
        CGFloat colorComponents[8] = {
            0.0, 0.0, 0.0, upperAlpha,  // Upper color.
            0.0, 0.0, 0.0, bottomAlpha  // Bottom color.
        };
        CGGradientRef gradient =
        CGGradientCreateWithColorComponents(colorSpace, colorComponents, locations, 2);
        CGPoint startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGPoint endPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
        CGGradientRelease(gradient);
    };
    
    drawGradient(0.4, 0.6, self.frame);
    CGColorSpaceRelease(colorSpace);
}


@end
