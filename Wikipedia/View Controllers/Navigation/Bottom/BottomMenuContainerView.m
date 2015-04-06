//  Created by Monte Hurd on 2/6/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "BottomMenuContainerView.h"
#import "Defines.h"

@implementation BottomMenuContainerView

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect));
    CGContextSetStrokeColorWithColor(context, CHROME_OUTLINE_COLOR.CGColor);
    CGContextSetLineWidth(context, CHROME_OUTLINE_WIDTH);
    CGContextStrokePath(context);
}

@end
