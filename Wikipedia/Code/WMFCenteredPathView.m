//  Created by Monte Hurd on 8/26/14.

#import "WMFCenteredPathView.h"

@interface WMFCenteredPathView ()

@property (nonatomic) CGPathRef path;
@property (nonatomic) CGFloat strokeWidth;
@property (strong, nonatomic) UIColor* strokeColor;
@property (strong, nonatomic) UIColor* fillColor;

@end

@implementation WMFCenteredPathView

- (id)initWithPath:(CGPathRef)newPath
       strokeWidth:(CGFloat)strokeWidth
       strokeColor:(UIColor*)strokeColor
         fillColor:(UIColor*)fillColor;
{
    self = [super init];
    if (self) {
        self.path        = newPath;
        self.strokeWidth = strokeWidth;
        self.strokeColor = strokeColor;
        self.fillColor   = fillColor;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGPathRef path = self.path;

    CGRect boundingBox = CGPathGetBoundingBox(path);

    // Translate path to origin zero zero.
    CGAffineTransform zeroZeroXF = CGAffineTransformMakeTranslation(-boundingBox.origin.x, -boundingBox.origin.y);
    path        = CGPathCreateCopyByTransformingPath(path, &zeroZeroXF);
    boundingBox = CGPathGetBoundingBox(path);

    // Fitting / Centering code below based on: http://stackoverflow.com/a/15936794

    // Calculate scale to fit path in rect.
    CGFloat boundingBoxAspectRatio = CGRectGetWidth(boundingBox) / CGRectGetHeight(boundingBox);
    CGFloat viewAspectRatio        = CGRectGetWidth(rect) / CGRectGetHeight(rect);
    CGFloat scaleFactor            = 1.0;
    if (boundingBoxAspectRatio > viewAspectRatio) {
        scaleFactor = (CGRectGetWidth(rect) - (self.strokeWidth * 2.0f)) / CGRectGetWidth(boundingBox);
    } else {
        scaleFactor = (CGRectGetHeight(rect) - (self.strokeWidth * 2.0f)) / CGRectGetHeight(boundingBox);
    }

    // Apply new scale to path.
    CGAffineTransform scaleTransform = CGAffineTransformIdentity;
    scaleTransform = CGAffineTransformScale(scaleTransform, scaleFactor, scaleFactor);
    scaleTransform = CGAffineTransformTranslate(scaleTransform, -CGRectGetMinX(boundingBox), -CGRectGetMinY(boundingBox));

    // Calculate transform to center newly scaled path in rect.
    CGSize scaledSize   = CGSizeApplyAffineTransform(boundingBox.size, CGAffineTransformMakeScale(scaleFactor, scaleFactor));
    CGSize centerOffset = CGSizeMake((CGRectGetWidth(rect) - scaledSize.width) / (scaleFactor * 2.0),
                                     (CGRectGetHeight(rect) - scaledSize.height) / (scaleFactor * 2.0));
    scaleTransform = CGAffineTransformTranslate(scaleTransform, centerOffset.width, centerOffset.height);

    // Apply centering transform.
    CGPathRef scaledPath = CGPathCreateCopyByTransformingPath(path, &scaleTransform);

    // Draw!
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, self.strokeWidth);
    [self.fillColor setFill];
    [self.strokeColor setStroke];
    CGContextAddPath(ctx, scaledPath);
    CGContextDrawPath(ctx, kCGPathFillStroke);

    CGPathRelease(scaledPath); // release the copied path
}

@end
