#import <UIKit/UIKit.h>

@interface UIImage (WMFStyle)

+ (UIImage *)wmf_placeholderImage;

+ (instancetype)wmf_imageFromColor:(UIColor *)color;

+ (UIImage *)wmf_imageFlippedForRTLLayoutDirectionNamed:(NSString *)name;

@end
