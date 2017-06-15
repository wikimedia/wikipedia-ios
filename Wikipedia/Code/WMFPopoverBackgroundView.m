#import "WMFPopoverBackgroundView.h"

@interface WMFPopoverBackgroundView ()

@property (nonatomic, readwrite) CGFloat arrowOffset;
@property (nonatomic, readwrite) UIPopoverArrowDirection arrowDirection;
@property (nonatomic, strong) UIImageView *arrowImageView;

@end

@implementation WMFPopoverBackgroundView

@synthesize arrowDirection = _arrowDirection;
@synthesize arrowOffset = _arrowOffset;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.arrowColor = [UIColor blackColor];
        self.arrowDirection = UIPopoverArrowDirectionAny;
    }
    return self;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self addSubview:self.arrowImageView];
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] initWithImage:[self arrowImageWithSize:CGSizeMake([[self class] arrowBase], [[self class] arrowHeight])]];
    }
    return _arrowImageView;
}

+ (CGFloat)arrowBase {
    return 24.0f;
}

+ (CGFloat)arrowHeight {
    return 13.0f;
}

+ (UIEdgeInsets)contentViewInsets {
    return UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
}

+ (BOOL)wantsDefaultContentAppearance {
    return NO;
}

- (void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection {
    _arrowDirection = arrowDirection;
    [self setNeedsLayout];
}

- (UIPopoverArrowDirection)arrowDirection {
    return _arrowDirection;
}

- (void)setArrowOffset:(CGFloat)arrowOffset {
    _arrowOffset = arrowOffset;
    [self setNeedsLayout];
}

- (CGFloat)arrowOffset {
    return _arrowOffset;
}

- (void)layoutSubviews {
    // Note: Don't call super in layoutSubviews if you want "wantsDefaultContentAppearance" to
    // return NO. A UIKit bug prevents wantsDefaultContentAppearance NO from taking effect otherwise.
    if ([[self class] wantsDefaultContentAppearance]) {
        [super layoutSubviews];
    }

    [self repositionAndRotateArrow];
}

- (void)repositionAndRotateArrow {
    CGFloat height = [[self class] arrowHeight];
    CGRect frame = self.frame;
    CGPoint center = CGPointZero;
    CGFloat angle = 0;

    if (self.arrowDirection == UIPopoverArrowDirectionUp) {
        frame.origin.y += height;
        frame.size.height -= height;
        angle = 0;
        center = CGPointMake(frame.size.width * 0.5 + self.arrowOffset, height * 0.5);
    } else if (self.arrowDirection == UIPopoverArrowDirectionDown) {
        frame.size.height -= height;
        angle = M_PI;
        center = CGPointMake(frame.size.width * 0.5 + self.arrowOffset, frame.size.height + height * 0.5);
    } else if (self.arrowDirection == UIPopoverArrowDirectionLeft) {
        frame.origin.x += height;
        frame.size.width -= height;
        angle = M_PI_2 * 3.0;
        center = CGPointMake(height * 0.5, frame.size.height * 0.5 + self.arrowOffset);
    } else if (self.arrowDirection == UIPopoverArrowDirectionRight) {
        frame.size.width -= height;
        angle = M_PI_2;
        center = CGPointMake(frame.size.width + height * 0.5, frame.size.height * 0.5 + self.arrowOffset);
    }

    self.arrowImageView.center = center;
    self.arrowImageView.transform = CGAffineTransformMakeRotation(angle);
}

- (UIImage *)arrowImageWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, (size.width / 2.0f), 2.0f);
    CGPathAddLineToPoint(path, NULL, size.width, size.height + 1.0f);
    CGPathAddLineToPoint(path, NULL, 0.0f, size.height + 1.0f);
    CGPathCloseSubpath(path);
    CGContextAddPath(context, path);
    CGPathRelease(path);

    CGContextSetFillColorWithColor(context, self.arrowColor.CGColor);
    CGContextDrawPath(context, kCGPathFill);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
