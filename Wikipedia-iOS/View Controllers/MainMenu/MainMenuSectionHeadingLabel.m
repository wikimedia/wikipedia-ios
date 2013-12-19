//  Created by Monte Hurd on 12/5/13.

#import "MainMenuSectionHeadingLabel.h"

@implementation MainMenuSectionHeadingLabel

- (id)init
{
    self = [super init];
    if (self) {
        //self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
        self.numberOfLines = 2;
        self.lineBreakMode = NSLineBreakByWordWrapping;
        self.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
//self.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.1];
        self.textColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        self.useDottedLine = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if(!self.useDottedLine) return;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, CGRectGetMinX(rect), 1);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), 1);
    CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor] );
    CGContextSetLineWidth(context, 1.0);
    CGFloat dashPhase = 0.0;
    CGFloat dashLengths[] = {1.0f / [UIScreen mainScreen].scale, 2.0f};
    CGContextSetLineDash(context, dashPhase, dashLengths, 2);
    CGContextStrokePath(context);
}

@end
