//  Created by Monte Hurd on 2/6/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TopMenuContainerView.h"
#import "Defines.h"

@implementation TopMenuContainerView

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.showBottomBorder = YES;
    }
    return self;
}

- (void)setShowBottomBorder:(BOOL)showBottomBorder {
    _showBottomBorder = showBottomBorder;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (!self.showBottomBorder) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGContextSetStrokeColorWithColor(context, CHROME_OUTLINE_COLOR.CGColor);
    CGContextSetLineWidth(context, CHROME_OUTLINE_WIDTH);
    CGContextStrokePath(context);
}

@end
