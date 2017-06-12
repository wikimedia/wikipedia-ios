#import <WMF/UIImage+WMFStyle.h>

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

+ (UIImage *)wmf_imageFlippedForRTLLayoutDirectionNamed:(NSString *)name {
    return [[UIImage imageNamed:name] imageFlippedForRightToLeftLayoutDirection];
}

@end
