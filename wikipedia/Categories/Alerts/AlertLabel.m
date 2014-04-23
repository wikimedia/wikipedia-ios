//  Created by Monte Hurd on 12/9/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AlertLabel.h"

@interface AlertLabel()

@property (nonatomic) UIEdgeInsets paddingEdgeInsets;

@end

@implementation AlertLabel

- (id)init
{
    self = [super init];
    if (self) {
        self.alpha = 0.0f;

        self.paddingEdgeInsets = UIEdgeInsetsMake(1, 10, 1, 10);

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
    CGContextSetLineWidth(context, 1.0f / [UIScreen mainScreen].scale);

    CGContextStrokePath(context);
}

// Label padding edge insets! From: http://stackoverflow.com/a/21934948

-(void)drawTextInRect:(CGRect)rect {
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.paddingEdgeInsets)];
}

-(CGSize)intrinsicContentSize {
    UIEdgeInsets insets = self.paddingEdgeInsets;

    // This needs to come before the call to super so the super call can take
    // into account the padding. Needed because the padding can affect how many
    // lines are being displayed, which can increase the intrinsicContentSize
    // height.
    self.preferredMaxLayoutWidth = self.bounds.size.width - (insets.left + insets.right);

    CGSize contentSize = [super intrinsicContentSize];
    contentSize.height += insets.top + insets.bottom;
    contentSize.width += insets.left + insets.right;
    return contentSize;
}

@end
