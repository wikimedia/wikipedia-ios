@import UIKit;

@interface UIImage (WMFStyle)

+ (instancetype)wmf_imageFromColor:(UIColor *)color;

+ (UIImage *)wmf_imageFlippedForRTLLayoutDirectionNamed:(NSString *)name;

@end
