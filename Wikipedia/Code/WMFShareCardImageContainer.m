#import "WMFShareCardImageContainer.h"
#import "UIImage+WMFFocalImageDrawing.h"
#import "WMFGeometry.h"

@interface WMFShareCardImageContainer ()
@property (nonatomic) CGRect focalBounds;
@end

@implementation WMFShareCardImageContainer

- (void)setLeadImage:(MWKImage *)leadImage {
    if (_leadImage == leadImage) {
        return;
    }
    _leadImage = leadImage;
    [_leadImage isDownloaded:^(BOOL isDownloaded) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.focalBounds = isDownloaded ? [self getPrimaryFocalRectFromCanonicalLeadImage] : CGRectZero;
            [self setNeedsDisplay];
        });
    }];
}
    
- (CGRect)getPrimaryFocalRectFromCanonicalLeadImage {
    NSAssert([self.leadImage isVariantOfImage:self.leadImage.article.image], @"Primary focal rect sought on non-lead image.");

    // Focal rect info is parked on the article.image which is the originally retrieved lead image.
    // self.leadImage is potentially a larger variant, which is why here the focal rect unit coords are
    // sought on self.leadImage.article.image
    CGRect focalRect = CGRectZero;
    NSArray *focalRects = [self.leadImage.article.image allNormalizedFaceBounds];
    if (focalRects.count > 0) {
        focalRect = WMFDenormalizeRectUsingSize([[focalRects firstObject] CGRectValue], self.leadImage.size);
    }
    return focalRect;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawGradientBackground];

    [self.image wmf_drawInRect:rect
                   focalBounds:self.focalBounds
                focalHighlight:NO
                     blendMode:kCGBlendModeMultiply
                         alpha:1.0];
}

// TODO: in follow-up patch, factor drawGradientBackground from
// LeadImageContainer so that it is more generalizable for setting
// gradient segments.
- (void)drawGradientBackground {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    void (^drawGradient)(CGFloat, CGFloat, CGRect) = ^void(CGFloat upperAlpha, CGFloat bottomAlpha, CGRect rect) {
        CGFloat locations[] = {
            0.0, // Upper color stop.
            1.0  // Bottom color stop.
        };
        CGFloat colorComponents[8] = {
            0.0, 0.0, 0.0, upperAlpha, // Upper color.
            0.0, 0.0, 0.0, bottomAlpha // Bottom color.
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
