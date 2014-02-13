//  Created by Monte Hurd on 11/23/13.

#import "NavBarTextField.h"
#import "Defines.h"

@implementation NavBarTextField

@synthesize placeholder = _placeholder;
@synthesize placeholderColor = _placeholderColor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.placeholderColor = SEARCH_FIELD_PLACEHOLDER_TEXT_COLOR;
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

-(void)setPlaceholder:(NSString *)placeholder
{
        _placeholder = placeholder;
        self.attributedPlaceholder = [self getAttributedPlaceholderForString:(!placeholder) ? @"": placeholder];
}

-(void)setPlaceholderColor:(UIColor *)placeholderColor
{
    _placeholderColor = placeholderColor;
    self.placeholder = self.placeholder;
}

-(NSAttributedString *)getAttributedPlaceholderForString:(NSString *)string
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:string];

    [str addAttribute:NSFontAttributeName
                value:SEARCH_FONT_HIGHLIGHTED
                range:NSMakeRange(0, str.length)];

    [str addAttribute:NSForegroundColorAttributeName
                value:self.placeholderColor
                range:NSMakeRange(0, str.length)];

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
