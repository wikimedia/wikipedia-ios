#import "UIColor+WMFHexColor.h"

@implementation UIColor (WMF_HexColor)

+ (UIColor *)wmf_colorWithHex:(NSInteger)hex
                        alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16)) / 255.0
                           green:((float)((hex & 0xFF00) >> 8)) / 255.0
                            blue:((float)(hex & 0xFF)) / 255.0
                           alpha:alpha];
}

+ (UIColor *)wmf_colorWithHex:(NSInteger)hex {
    return [UIColor wmf_colorWithHex:hex alpha:1.0];
}

- (NSString *)wmf_hexStringIncludingAlpha:(BOOL)includeAlpha {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    if (includeAlpha) {
        return [NSString stringWithFormat:@"%02x%02x%02x%02x",
                                          (int)(255.0 * red),
                                          (int)(255.0 * green),
                                          (int)(255.0 * blue),
                                          (int)(255.0 * alpha)];
    } else {
        return [NSString stringWithFormat:@"%02x%02x%02x",
                                          (int)(255.0 * red),
                                          (int)(255.0 * green),
                                          (int)(255.0 * blue)];
    }
}

@end
