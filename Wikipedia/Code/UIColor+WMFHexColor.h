#import <UIKit/UIKit.h>

@interface UIColor (WMF_HexColor)

+ (UIColor *)wmf_colorWithHex:(NSInteger)hex
                        alpha:(CGFloat)alpha;

- (NSString *)wmf_hexStringWithAlpha:(BOOL)useAlpha;

@end
