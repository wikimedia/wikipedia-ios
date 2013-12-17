//  Created by Monte Hurd on 11/23/13.

#import "SearchBarTextField.h"

@implementation SearchBarTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// Adds left padding without messing up leftView or rightView.
// From: http://stackoverflow.com/a/14357720

- (CGRect)textRectForBounds:(CGRect)bounds {
    CGRect ret = [super textRectForBounds:bounds];
    ret.origin.x = ret.origin.x + 10;
    ret.size.width = ret.size.width - 20;
    return ret;
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

// Draw separator line at bottom for iOS 6.

- (void)drawRect:(CGRect)rect {
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect));
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor] );
        CGContextSetLineWidth(context, 1.0);
        CGContextStrokePath(context);
    }
}

@end
