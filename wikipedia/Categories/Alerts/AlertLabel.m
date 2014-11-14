//  Created by Monte Hurd on 12/9/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AlertLabel.h"
#import "WMF_Colors.h"
#import "Defines.h"
#import "UIView+RemoveConstraints.h"

@interface AlertLabel()

@property (nonatomic) CGFloat duration;
@property (nonatomic) UIEdgeInsets padding;
@property (nonatomic, strong) id text;
@property (nonatomic) AlertType type;

@end

@implementation AlertLabel

-(id)initWithText:(id)text duration:(CGFloat)duration padding:(UIEdgeInsets)padding type:(AlertType)type;
{
    self = [super init];
    if (self) {

        self.font = [UIFont systemFontOfSize:ALERT_FONT_SIZE];
        self.textAlignment = NSTextAlignmentCenter;
        self.textColor = ALERT_TEXT_COLOR;

        if([text isKindOfClass:[NSAttributedString class]]){
            self.attributedText = text;
        }else{
            self.text = text;
        }

        self.duration = duration;
        self.padding = padding;
        self.type = type;
        self.minimumScaleFactor = 0.2;
        self.numberOfLines = 0;
        self.lineBreakMode = NSLineBreakByWordWrapping;
        self.backgroundColor = ALERT_BACKGROUND_COLOR;
        self.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

-(void)tap:(UITapGestureRecognizer *)recognizer
{
    if(recognizer.state == UIGestureRecognizerStateEnded){
        // Hide without delay.
        [self hide];
    }
}

-(void)hide
{
    // Don't do anything if this view has yet to move to its superview.
    if (!self.superview) return;

    // This is important. Without this, rapid taps on save icon followed by save icon long press to
    // bring up the saved pages list followed by selection would cause crash on iOS 6. Crash related
    // to the constraint system causeing the alert view to be retained too long.
    [self removeConstraintsOfViewFromView:self.superview];

    [self removeFromSuperview];
}

-(void)fade
{
    [self fadeAfterDelay:0];
}

-(void)fadeAfterDelay:(CGFloat)delay
{
    // Don't do anything if this view has yet to move to its superview.
    if (!self.superview) return;
    
    [UIView animateWithDuration:0.35
                          delay:delay
                        options:0
                     animations:^{
                         self.alpha = 0.0;
                     }
                     completion:^(BOOL done){
                         [self hide];
                     }];
}

-(void)didMoveToSuperview
{
    if (self.duration == -1) return;
    [self fadeAfterDelay:self.duration];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();

    switch (self.type) {
        case ALERT_TYPE_TOP:
            CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect));
            CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
            break;
        case ALERT_TYPE_BOTTOM:
            CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
            CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect));
            break;
        default: //ALERT_TYPE_FULLSCREEN
            return;
            break;
    }

    CGContextSetStrokeColorWithColor(context, CHROME_OUTLINE_COLOR.CGColor);
    CGContextSetLineWidth(context, CHROME_OUTLINE_WIDTH);

    CGContextStrokePath(context);
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING ALERT VIEW!");
}
*/

@end
