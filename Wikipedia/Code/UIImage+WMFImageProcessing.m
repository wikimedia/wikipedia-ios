#import "UIImage+WMFImageProcessing.h"

@implementation UIImage (WMFImageProcessing)

- (CIImage *__nonnull)wmf_getOrCreateCIImage {
    return self.CIImage ?: [[CIImage alloc] initWithCGImage:self.CGImage];
}

- (UIImage *__nonnull)wmf_optimizedImage {
    CGSize imageSize = self.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, YES, [UIScreen mainScreen].scale);
    [self drawInRect: CGRectMake(0, 0, imageSize.width, imageSize.height)];
    UIImage *optimizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return optimizedImage;
}

@end
