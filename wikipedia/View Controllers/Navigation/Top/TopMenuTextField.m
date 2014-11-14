//  Created by Monte Hurd on 11/23/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TopMenuTextField.h"
#import "Defines.h"

@implementation TopMenuTextField

@synthesize placeholder = _placeholder;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.borderStyle = UITextBorderStyleNone;
        self.layer.cornerRadius = 6.0f * MENUS_SCALE_MULTIPLIER;
        self.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    }
    return self;
}

// Adds left padding without messing up leftView or rightView.
// From: http://stackoverflow.com/a/14357720
- (CGRect)textRectForBounds:(CGRect)bounds {
    CGRect rect = [super textRectForBounds:bounds];
    return CGRectInset(rect, 10.0f * MENUS_SCALE_MULTIPLIER, 0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

-(void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    self.attributedPlaceholder = [self getAttributedPlaceholderForString:(!placeholder) ? @"": placeholder];
}

-(NSAttributedString *)getAttributedPlaceholderForString:(NSString *)string
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:string];
    
    [str addAttributes: @{
                          NSForegroundColorAttributeName : SEARCH_FIELD_PLACEHOLDER_TEXT_COLOR
                          }
                 range: NSMakeRange(0, string.length)];
    return str;
}

/*
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
*/

@end
