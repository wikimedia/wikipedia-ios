//  Created by Monte Hurd and Adam Baso on 2/13/14.

#import "UIImage+ColorMask.h"

@implementation UIImage (ColorMask)

- (UIImage *)getImageOfColor:(CGColorRef)CGColor;
{
    CGColorSpaceRef colorSpace = CGColorGetColorSpace(CGColor);
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);
    if (colorSpaceModel != kCGColorSpaceModelRGB) {
        NSLog(@"Oops: 'getImageOfColor:' requires a color with a rgb color space, but was passed the following: %@", CGColor);
    }

    // Pass this method a color and it will return an image based on this image
    // but with any parts which were not transparent changed to be "color". This is
    // handier that it sounds for fine-tuning the appearance of button images without
    // the need for regenerating new pngs. Because of the way the clamp filter is set
    // up below, this method can be called repeatedly w/no image quality degradation.
    
    CIImage *adjustedImage = [CIImage imageWithCGImage:self.CGImage];

    // From Apple's "Core Image Filter Reference" doc about CIColorClamp:
    // "At each pixel, color component values less than those in inputMinComponents will be
    // increased to match those in inputMinComponents". So "inputMinComponents" is set below
    // to make any pixel which is not 100% clear become pure white.
    CIFilter *colorClampFilter = [CIFilter filterWithName:@"CIColorClamp"];
    [colorClampFilter setDefaults];
    [colorClampFilter setValue: adjustedImage forKey:@"inputImage"];
    [colorClampFilter setValue: [CIVector vectorWithX:1.0 Y:1.0 Z:1.0 W:0.0] forKey:@"inputMinComponents"];
    adjustedImage = [colorClampFilter outputImage];

    CIImage *backgroundImage = [CIImage imageWithColor:[CIColor colorWithCGColor:[UIColor clearColor].CGColor]];
    CIImage *colorImage = [CIImage imageWithColor:[CIColor colorWithCGColor:CGColor]];
    CIFilter *maskFilter = [CIFilter filterWithName:@"CIBlendWithMask"];
    [maskFilter setDefaults];
    [maskFilter setValue: colorImage forKey:@"inputImage"];
    [maskFilter setValue: backgroundImage forKey:@"inputBackgroundImage"];
    [maskFilter setValue: adjustedImage forKey:@"inputMaskImage"];
    adjustedImage = [maskFilter outputImage];

    //See: http://stackoverflow.com/a/15886422/135557
    CGImageRef imageRef = [[CIContext contextWithOptions:nil] createCGImage:adjustedImage fromRect:adjustedImage.extent];
    UIImage *outputImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return outputImage;
}

@end
