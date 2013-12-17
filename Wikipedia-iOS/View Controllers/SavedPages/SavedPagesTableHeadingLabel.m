//  Created by Monte Hurd on 12/5/13.

#import "SavedPagesTableHeadingLabel.h"

@implementation SavedPagesTableHeadingLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, CGRectGetMinX(rect)+10, CGRectGetMaxY(rect) - 4);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect)-10, CGRectGetMaxY(rect) - 4);
    CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor] );
    CGContextSetLineWidth(context, 1.0);
    CGFloat dashPhase = 0.0;
    CGFloat dashLengths[] = {1.0f / [UIScreen mainScreen].scale, 2.0f};
    CGContextSetLineDash(context, dashPhase, dashLengths, 2);
    CGContextStrokePath(context);
}

@end
