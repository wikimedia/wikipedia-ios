//  Created by Monte Hurd on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIColor+WMFHexColor.h"

@implementation UIColor (WMF_HexColor)

+ (UIColor*)wmf_colorWithHex:(NSInteger)hex
                       alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16)) / 255.0
                           green:((float)((hex & 0xFF00) >> 8)) / 255.0
                            blue:((float)(hex & 0xFF)) / 255.0
                           alpha:alpha];
}

- (NSString*)wmf_hexString {
    // From: http://stackoverflow.com/a/26341062
    const CGFloat* components = CGColorGetComponents(self.CGColor);
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(components[0] * 255),
            lroundf(components[1] * 255),
            lroundf(components[2] * 255)];
}

@end
