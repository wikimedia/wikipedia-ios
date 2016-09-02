#import "UIImage+WMFImageProcessing.h"

@implementation UIImage (WMFImageProcessing)

- (CIImage *__nonnull)wmf_getOrCreateCIImage {
    return self.CIImage ?: [[CIImage alloc] initWithCGImage:self.CGImage];
}

@end
