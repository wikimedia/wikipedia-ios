//  Created by Monte Hurd on 2/6/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TopMenuContainerView.h"

@implementation TopMenuContainerView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.showBottomBorder = YES;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (!self.showBottomBorder) return;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor] );
    CGContextSetLineWidth(context, 1.0f / [UIScreen mainScreen].scale);
    CGContextStrokePath(context);
}

@end
