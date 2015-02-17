
#import "WMFBorderButton.h"
#import <objc/runtime.h>

static CGFloat const kWMFBorderButtonWidthPadding = 20.0;
static CGFloat const kWMFBorderButtonHeightPadding = 10.0;
@implementation WMFBorderButton

@dynamic borderWidth, cornerRadius;

#pragma mark - Convienence

+ (WMFBorderButton *)standardBorderButton{
    
    return [WMFBorderButton buttonWithBorderWidth:1.0 cornerRadius:4.0 color:[UIColor colorWithRed:0.051 green:0.482 blue:0.984 alpha:1]];
}

+ (WMFBorderButton *)buttonWithBorderWidth:(CGFloat)width cornerRadius:(CGFloat)radius color:(UIColor*)color;
{
    WMFBorderButton* button = [WMFBorderButton buttonWithType:UIButtonTypeCustom];
    button.layer.masksToBounds = YES;
    button.borderWidth = width;
    button.cornerRadius = radius;
    button.borderColor = color;
    [button setTitleColor:color forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
    [button setAdjustsImageWhenHighlighted:NO];
    
    return button;
}

#pragma mark - Runtime

- (id)forwardingTargetForSelector:(SEL)aSelector{
    
    if(sel_isEqual(aSelector, @selector(setBorderWidth:)) ||
       sel_isEqual(aSelector, @selector(borderWidth)) ||
       sel_isEqual(aSelector, @selector(setCornerRadius:)) ||
       sel_isEqual(aSelector, @selector(cornerRadius))
       ){
        
        [self setNeedsDisplay];
        [self setNeedsLayout];
        [self setNeedsUpdateConstraints];
        return self.layer;
    }
    
    return [super forwardingTargetForSelector:aSelector];
}

#pragma mark - Accessors

- (void)setBorderColor:(UIColor *)borderColor{
    
    self.layer.borderColor = borderColor.CGColor;
    [self setNeedsDisplay];
    [self setNeedsLayout];
    [self setNeedsUpdateConstraints];
}

- (UIColor*)borderColor{
    
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

#pragma mark - UIView

- (void)sizeToFit{
    
    [super sizeToFit];
    CGRect f = self.frame;
    f.size.width += kWMFBorderButtonWidthPadding;
    f.size.height += kWMFBorderButtonHeightPadding;
}

- (CGSize)intrinsicContentSize{
    
    CGSize s = [super intrinsicContentSize];
    s.width += kWMFBorderButtonWidthPadding;
    s.height += kWMFBorderButtonHeightPadding;
    return s;
}

@end
