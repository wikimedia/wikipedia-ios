#import "UIImage+WMFStyle.h"
#import "NSProcessInfo+WMFOperatingSystemVersionChecks.h"

@implementation UIImage (WMFStyle)

+ (UIImage *)wmf_placeholderImage {
  static UIImage *img;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    img = [[UIImage imageNamed:@"image-placeholder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  });
  return img;
}

+ (instancetype)wmf_imageFromColor:(UIColor *)color {
  CGRect rect = CGRectMake(0, 0, 1, 1);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (UIImage *)wmf_imageFlippedForRTLLayoutDirectionIfAtLeastiOS9 {
  return ([[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]) ? self : self.imageFlippedForRightToLeftLayoutDirection;
}

+ (UIImage *)wmf_imageFlippedForRTLLayoutDirectionNamed:(NSString *)name {
  return [[UIImage imageNamed:name] wmf_imageFlippedForRTLLayoutDirectionIfAtLeastiOS9];
}

@end
