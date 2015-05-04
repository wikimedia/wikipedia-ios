

#import "WMFShareCardImageContainer.h"
#import "UIImage+WMFFocalImageDrawing.h"
#import "WMFFaceDetector.h"

@interface WMFShareCardImageContainer ()

@property(nonatomic, strong) WMFFaceDetector* faceDetector;
@property(nonatomic) CGRect faceBounds;

@end

@implementation WMFShareCardImageContainer

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.faceDetector = [[WMFFaceDetector alloc] init];
    }
    return self;
}

- (void)setImage:(UIImage*)image {
    _image = image;
    [self.faceDetector setImageWithUIImage:image];
    [self.faceDetector detectFaces];
    self.faceBounds = [[[self.faceDetector allFaces] firstObject] bounds];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawGradientBackground];

    [self.image wmf_drawInRect:rect
                   focalBounds:self.faceBounds
                focalHighlight:NO
                     blendMode:kCGBlendModeMultiply
                         alpha:1.0];
}

// TODO: in follow-up patch, factor drawGradientBackground from
// LeadImageContainer so that it is more generalizable for setting
// gradient segments.
- (void)drawGradientBackground {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context       = UIGraphicsGetCurrentContext();

    void (^ drawGradient)(CGFloat, CGFloat, CGRect) = ^void (CGFloat upperAlpha, CGFloat bottomAlpha, CGRect rect) {
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
        CGPoint endPoint   = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
        CGGradientRelease(gradient);
    };

    drawGradient(0.4, 0.6, self.frame);
    CGColorSpaceRelease(colorSpace);
}

@end
