//  Created by Monte Hurd on 12/9/13.

#import "AlertLabel.h"

@implementation AlertLabel

- (id)init
{
    self = [super init];
    if (self) {
        self.alpha = 0.0f;
        
        self.minimumScaleFactor = 0.2;
        self.font = [UIFont systemFontOfSize:10];
        self.textAlignment = NSTextAlignmentCenter;
        self.textColor = [UIColor darkGrayColor];
        self.numberOfLines = 10;
        self.lineBreakMode = NSLineBreakByWordWrapping;
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
        self.userInteractionEnabled = YES;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

-(void)tap
{
    // Hide without delay.
    self.alpha = 0.0f;
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
