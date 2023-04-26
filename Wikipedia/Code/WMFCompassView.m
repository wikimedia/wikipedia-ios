#import "WMFCompassView.h"
@import WMF.WMFGeometry;
@import WMF.Swift;
@import WMF.WMFMath;
@import WMF.WMFLocalization;

static CGFloat const WMFCompassPadding = 18.0;

static CGFloat const WMFCompassLineWidth = 1.0;
static NSUInteger const WMFCompassLineCount = 40;

static CGFloat const WMFCompassOppositeLineWidth = 2.0;

@implementation WMFCompassView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    self.lineColor = [UIColor wmf_green_600];
}

- (void)setAngleRadians:(double)angleRadians {
    _angleRadians = angleRadians;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    // All sizes/lengths defined relatively so everything scales magically if the
    // size of the image rect or self.padding are adjusted.

    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat onePx = 1.0f / scale;
    CGFloat borderWidth = 1.0f / scale;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, borderWidth);

    double diameter = rect.size.width;
    double radius = diameter / 2.0f;

    CGColorRef tickColor = self.lineColor.CGColor;
    CGContextSetFillColorWithColor(ctx, tickColor);
    CGContextSetStrokeColorWithColor(ctx, tickColor);

    // Draw compass lines.
    CGFloat compassLineLength = (radius - (WMFCompassPadding)) * 0.06f;
    CGFloat compassLineRadius = (radius - (WMFCompassPadding)) * 1.15f;
    [self drawCompassLinesInContext:ctx
                             center:CGPointMake(radius, radius)
                             radius:compassLineRadius
                               size:CGSizeMake(WMFCompassLineWidth / scale, compassLineLength)
                              count:WMFCompassLineCount];

    CGColorRef arrowColor = self.lineColor.CGColor;
    CGContextSetFillColorWithColor(ctx, arrowColor);
    CGContextSetStrokeColorWithColor(ctx, arrowColor);

    // Draw opposite tick line.
    CGFloat oppositeTickLength = (compassLineLength * 3.0f);
    [self drawOppositeLineInContext:ctx
                             center:CGPointMake(radius, radius)
                             radius:compassLineRadius
                               size:CGSizeMake(WMFCompassOppositeLineWidth / scale, oppositeTickLength)];

    // Draw tick (arrow-like directional indicator).
    CGFloat tickPercentOfRectWidth = 0.115;
    CGFloat tickPercentOfRectHeight = 0.135;
    CGSize tickSize =
        CGSizeMake(
            (rect.size.width - (WMFCompassPadding * 2.0f)) * tickPercentOfRectWidth,
            (rect.size.height - (WMFCompassPadding * 2.0f)) * tickPercentOfRectHeight);
    [self drawTickInContext:ctx
                     center:CGPointMake(radius, radius)
                     radius:compassLineRadius - onePx
                       size:tickSize];

    CGContextDrawPath(ctx, kCGPathStroke);

    [super drawRect:rect];
}

- (void)drawOppositeLineInContext:(CGContextRef)ctx
                           center:(CGPoint)center
                           radius:(CGFloat)radius
                             size:(CGSize)size {
    CGContextSetLineWidth(ctx, size.width);

    // Rotate and translate.
    CGContextSaveGState(ctx);
    // Move to center of circle.
    CGContextTranslateCTM(ctx, center.x, center.y);
    // Rotate.
    CGContextRotateCTM(ctx, self.angleRadians);
    // Rotate to other side.
    CGContextRotateCTM(ctx, DEGREES_TO_RADIANS(180.0f));

    // Move to location to draw tick.
    CGContextTranslateCTM(ctx, 0, -radius);
    CGContextTranslateCTM(ctx, -(size.width / 2.0f), -(size.height));

    // Make tick shape.
    UIBezierPath *path = [[UIBezierPath alloc] init];
    CGRect tickRect = CGRectMake(0, 0, size.width, size.height);

    CGPoint tp = CGPointMake(CGRectGetMidX(tickRect), CGRectGetMinY(tickRect));
    CGPoint bp = CGPointMake(CGRectGetMidX(tickRect), CGRectGetMaxY(tickRect));

    [path moveToPoint:tp];
    [path addLineToPoint:bp];

    CGContextBeginPath(ctx);

    // Stroke tick.
    CGContextAddPath(ctx, path.CGPath);
    CGContextDrawPath(ctx, kCGPathFillStroke);
    //CGContextStrokeRect(ctx, tickRect);

    // Stroke tick.
    //CGContextSetLineWidth(ctx, borderWidth);
    //CGContextAddPath(ctx, path.CGPath);
    //CGContextDrawPath(ctx, kCGPathFillStroke);

    CGContextRestoreGState(ctx);
}

- (void)drawTickInContext:(CGContextRef)ctx
                   center:(CGPoint)center
                   radius:(CGFloat)radius
                     size:(CGSize)size {
    // Rotate and translate.
    CGContextSaveGState(ctx);
    // Move to center of circle.
    CGContextTranslateCTM(ctx, center.x, center.y);
    // Rotate.
    CGContextRotateCTM(ctx, self.angleRadians);

    // Move to location to draw tick.
    CGContextTranslateCTM(ctx, 0, -radius);
    CGContextTranslateCTM(ctx, -(size.width / 2.0f), -(size.height));

    // Make tick shape.
    UIBezierPath *path = [[UIBezierPath alloc] init];
    CGRect tickRect = CGRectMake(0, 0, size.width, size.height);

    // Determines how far down from the vertical center the dots forming the base of the
    // tick triangleRadians are.
    CGFloat midpointDescent = size.height * 0.1666;

    CGPoint p1 = CGPointMake(CGRectGetMinX(tickRect), CGRectGetMaxY(tickRect));
    CGPoint p2 = CGPointMake(CGRectGetMinX(tickRect), CGRectGetMidY(tickRect) + midpointDescent);
    CGPoint p3 = CGPointMake(CGRectGetMidX(tickRect), CGRectGetMinY(tickRect));
    CGPoint p4 = CGPointMake(CGRectGetMaxX(tickRect), CGRectGetMidY(tickRect) + midpointDescent);
    CGPoint p5 = CGPointMake(CGRectGetMaxX(tickRect), CGRectGetMaxY(tickRect));

    [path moveToPoint:p1];
    [path addLineToPoint:p2];
    [path addLineToPoint:p3];
    [path addLineToPoint:p4];
    [path addLineToPoint:p5];

    [path closePath];

    CGContextBeginPath(ctx);

    // Fill tick.
    CGContextAddPath(ctx, path.CGPath);
    CGContextDrawPath(ctx, kCGPathFill);

    // Stroke tick.
    //CGContextSetLineWidth(ctx, borderWidth);
    //CGContextAddPath(ctx, path.CGPath);
    //CGContextDrawPath(ctx, kCGPathFillStroke);

    CGContextRestoreGState(ctx);
}

- (void)drawCompassLinesInContext:(CGContextRef)ctx
                           center:(CGPoint)center
                           radius:(CGFloat)radius
                             size:(CGSize)size
                            count:(NSInteger)count {
    CGContextSetLineWidth(ctx, size.width);

    for (int i = 0; i < count; i++) {
        CGFloat j = (360.0f / count) * i;
        CGFloat k = DEGREES_TO_RADIANS(j);

        // Rotate and translate.
        CGContextSaveGState(ctx);
        // Move to center of circle.
        CGContextTranslateCTM(ctx, center.x, center.y);
        // Rotate.
        CGContextRotateCTM(ctx, k);

        // Move to location to draw tick.
        CGContextTranslateCTM(ctx, 0, -radius);
        CGContextTranslateCTM(ctx, -(size.width / 2.0f), -(size.height));

        // Make tick shape.
        UIBezierPath *path = [[UIBezierPath alloc] init];
        CGRect tickRect = CGRectMake(0, 0, size.width, size.height);

        CGPoint tp = CGPointMake(CGRectGetMidX(tickRect), CGRectGetMinY(tickRect));
        CGPoint bp = CGPointMake(CGRectGetMidX(tickRect), CGRectGetMaxY(tickRect));

        [path moveToPoint:tp];
        [path addLineToPoint:bp];

        CGContextBeginPath(ctx);

        // Stroke tick.
        CGContextAddPath(ctx, path.CGPath);
        CGContextDrawPath(ctx, kCGPathFillStroke);
        //CGContextStrokeRect(ctx, tickRect);
        CGContextRestoreGState(ctx);
    }
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    NSInteger clockDirection = WMFRadiansToClock(self.angleRadians);
    NSString *label = WMFLocalizedStringWithDefaultValue(@"compass-direction", nil, nil, @"at %1$@ o'clock", @"Spoken description of compass direction, e.g. \"at 3 o'clock\" means \"to the right\", \"at 11 o'clock\" means \"slightly to the left\", etc. %1$@ is the hour.");
    label = [NSString localizedStringWithFormat:label, [NSString localizedStringWithFormat:@"%@", @(clockDirection)]];
    return label;
}

@end
