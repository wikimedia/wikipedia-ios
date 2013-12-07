//  Created by Monte Hurd on 12/9/13.

#import "AlertLabel.h"

@implementation AlertLabel

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.alpha = 0.0f;
    }
    return self;
}

-(void)setHidden:(BOOL)hidden
{
    if (hidden){
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.35];
        [UIView setAnimationDelay:1.0f];
        [self setAlpha:0.0f];
        [UIView commitAnimations];
    }else{
        [self setAlpha:1.0f];
    }
}

-(void)setText:(NSString *)text
{
    if (text.length == 0){
        // Just fade out if message is set to empty string
        self.hidden = YES;
    }else{
        super.text = text;
        self.hidden = NO;
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor] );
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokePath(context);
}

@end
