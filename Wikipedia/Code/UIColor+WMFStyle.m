#import <WMF/UIColor+WMFStyle.h>

@implementation UIColor (WMFStyle)

- (instancetype)wmf_copyWithAlpha:(CGFloat)alpha {
    CGFloat r, g, b, _;
    [self getRed:&r green:&g blue:&b alpha:&_];
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

- (instancetype)wmf_colorByApplyingDim {
    // NOTE(bgerstle): 0.6 is hand-tuned to roughly match UIImageView's default tinting amount
    return [self wmf_colorByScalingComponents:0.6];
}

- (instancetype)wmf_colorByScalingComponents:(CGFloat)amount {
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:r * amount green:g * amount blue:b * amount alpha:a];
}

@end
