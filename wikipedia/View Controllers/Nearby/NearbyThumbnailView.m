//  Created by Monte Hurd on 8/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NearbyThumbnailView.h"
#import "WMF_Colors.h"
#import "Defines.h"

#define NEARBY_IMAGE_PADDING (16.0f * MENUS_SCALE_MULTIPLIER)

#define NEARBY_IMAGE_BORDER_WIDTH 1.0f
#define NEARBY_IMAGE_BORDER_COLOR [UIColor colorWithWhite:0.9 alpha:1.0].CGColor
#define NEARBY_TICK_COLOR WMF_COLOR_GREEN.CGColor

#define NEARBY_COMPASS_LINE_WIDTH 1.0f
#define NEARBY_COMPASS_LINE_COUNT 57
#define NEARBY_OPPOSITE_LINE_WIDTH 2.0f

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface NearbyThumbnailView()

@property (strong, nonatomic) UIImageView *thumbImageView;
@property (nonatomic) BOOL isPlaceholder;
@property (nonatomic) CGFloat padding;

@end

@implementation NearbyThumbnailView

-(void)setAngle:(double)angle
{
    _angle = angle;
    [self setNeedsDisplay];
}

-(void)setHeadingAvailable:(BOOL)headingAvailable
{
    _headingAvailable = headingAvailable;
    [self setNeedsDisplay];
}

-(void)setImage:(UIImage *)image isPlaceHolder:(BOOL)isPlaceholder;
{
    self.isPlaceholder = isPlaceholder;
    self.thumbImageView.image = image;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.padding = NEARBY_IMAGE_PADDING;
        self.angle = 0;
        self.thumbImageView = [[UIImageView alloc] init];
        self.thumbImageView.clipsToBounds = YES;
        self.thumbImageView.opaque = YES;
        self.thumbImageView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        self.thumbImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.thumbImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.thumbImageView];
        [self constrainImageView];
        self.isPlaceholder = NO;
        //self.layer.borderWidth = 1.0f;
        //self.layer.borderColor = [UIColor redColor].CGColor;
    }
    return self;
}

-(void)setIsPlaceholder:(BOOL)isPlaceholder
{
    _isPlaceholder = isPlaceholder;
    [self setNeedsLayout];
}

-(void)layoutSubviews
{
    [super layoutSubviews];

    self.thumbImageView.layer.cornerRadius = (self.thumbImageView.frame.size.width / 2.0f);
}

-(void)constrainImageView
{
    NSDictionary *views = @{
        @"thumbView": self.thumbImageView
    };

    NSDictionary *metrics = @{
        @"padding": @(self.padding)
    };

    NSArray *viewConstraintArrays = @
        [
         [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-(padding)-[thumbView]-(padding)-|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: views],
         
         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-(padding)-[thumbView]-(padding)-|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: views]
     ];
    [self addConstraints:[viewConstraintArrays valueForKeyPath:@"@unionOfArrays.self"]];
}

- (void)drawRect:(CGRect)rect
{
    // All sizes/lengths defined relatively so everything scales magically if the
    // size of the image rect or self.padding are adjusted.

    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat onePx = 1.0f / scale;
    CGFloat borderWidth = NEARBY_IMAGE_BORDER_WIDTH / scale;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, borderWidth);
    
    double diameter = rect.size.width;
    double radius = diameter / 2.0f;

    if (self.headingAvailable) {

        CGContextSetFillColorWithColor(ctx, NEARBY_TICK_COLOR);
        CGContextSetStrokeColorWithColor(ctx, NEARBY_TICK_COLOR);

        // Draw compass lines.
        CGFloat compassLineLength = (radius - (self.padding)) * 0.07f;
        CGFloat compassLineRadius = (radius - (self.padding)) * 1.15f;
        [self drawCompassLinesInContext: ctx
                                 center: CGPointMake(radius, radius)
                                 radius: compassLineRadius
                                   size: CGSizeMake(NEARBY_COMPASS_LINE_WIDTH / scale, compassLineLength)
                                  count: NEARBY_COMPASS_LINE_COUNT];

        // Draw opposite tick line.
        CGFloat oppositeTickLength = (compassLineLength * 3.0f);
        [self drawOppositeLineInContext: ctx
                                 center: CGPointMake(radius, radius)
                                 radius: compassLineRadius
                                   size: CGSizeMake(NEARBY_OPPOSITE_LINE_WIDTH / scale, oppositeTickLength)];

        // Draw tick (arrow-like directional indicator).
        CGFloat tickPercentOfRectWidth = 0.125;
        CGFloat tickPercentOfRectHeight = 0.135;
        CGSize tickSize =
            CGSizeMake(
                (rect.size.width - (self.padding * 2.0f)) * tickPercentOfRectWidth,
                (rect.size.height - (self.padding * 2.0f)) * tickPercentOfRectHeight
            );
        [self drawTickInContext: ctx
                         center: CGPointMake(radius, radius)
                         radius: compassLineRadius - onePx
                           size: tickSize];
    }
    
    CGContextSetStrokeColorWithColor(ctx, NEARBY_IMAGE_BORDER_COLOR);
    
    // Draw circle.
    CGContextAddEllipseInRect(ctx, CGRectInset(self.thumbImageView.frame, -(borderWidth - onePx), -(borderWidth - onePx)));
    CGContextDrawPath(ctx, kCGPathStroke);
    
    [super drawRect:rect];
}

-(void)drawOppositeLineInContext: (CGContextRef)ctx
                          center: (CGPoint)center
                          radius: (CGFloat)radius
                            size: (CGSize)size
{
    CGContextSetLineWidth(ctx, size.width);

    // Rotate and translate.
    CGContextSaveGState(ctx);
    // Move to center of circle.
    CGContextTranslateCTM(ctx, center.x, center.y);
    // Rotate.
    CGContextRotateCTM(ctx, self.angle);
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

-(void)drawTickInContext: (CGContextRef)ctx
                  center: (CGPoint)center
                  radius: (CGFloat)radius
                    size: (CGSize)size
{
    // Rotate and translate.
    CGContextSaveGState(ctx);
    // Move to center of circle.
    CGContextTranslateCTM(ctx, center.x, center.y);
    // Rotate.
    CGContextRotateCTM(ctx, self.angle);

    // Move to location to draw tick.
    CGContextTranslateCTM(ctx, 0, -radius);
    CGContextTranslateCTM(ctx, -(size.width / 2.0f), -(size.height));
    
    // Make tick shape.
    UIBezierPath *path = [[UIBezierPath alloc] init];
    CGRect tickRect = CGRectMake(0, 0, size.width, size.height);
    
    // Determines how far down from the vertical center the dots forming the base of the
    // tick triangle are.
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

-(void)drawCompassLinesInContext: (CGContextRef)ctx
                          center: (CGPoint)center
                          radius: (CGFloat)radius
                            size: (CGSize)size
                           count: (NSInteger)count
{
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
        CGContextTranslateCTM(ctx, -(size.width / 2.0f),  -(size.height));
        
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

@end
