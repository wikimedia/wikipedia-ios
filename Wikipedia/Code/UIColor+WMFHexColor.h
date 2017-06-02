#import <UIKit/UIKit.h>

@interface UIColor (WMF_HexColor)

/**
 UIColor from hex string representation

 @param hex   hex for the color in the format of 0xffffff
 @param alpha alpha value for color from 0.0 to 1.0

 @return UIColor from the hex and alpha values provided
 */
+ (UIColor *)wmf_colorWithHex:(NSInteger)hex
                        alpha:(CGFloat)alpha;

+ (UIColor *)wmf_colorWithHex:(NSInteger)hex; // Alpha defaults to 1.0

/**
 Hex string representation of UIColor

 @param includeAlpha controls whether alpha octet is added to the end of the string

 @return string in the format "ffffff" or "ffffffff" if includeAlpha in enabled
 */
- (NSString *)wmf_hexStringIncludingAlpha:(BOOL)includeAlpha;

@end
