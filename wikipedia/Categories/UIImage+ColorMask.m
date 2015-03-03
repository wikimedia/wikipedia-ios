//  Created by Monte Hurd and Adam Baso on 2/13/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIImage+ColorMask.h"

@implementation UIImage (ColorMask)

- (UIImage*)getImageOfColor:(CGColorRef)CGColor;
{
    const CGFloat* colorComponents = CGColorGetComponents(CGColor);
    CGFloat red                    = colorComponents[0];
    CGFloat green                  = colorComponents[1];
    CGFloat blue                   = colorComponents[2];

    if (CGColorSpaceGetModel(CGColorGetColorSpace(CGColor)) == kCGColorSpaceModelMonochrome) {
        red = green = blue = colorComponents[0];
    }

    CIImage* inputImage = [CIImage imageWithCGImage:self.CGImage];

    CIImage* outputImage = [CIFilter filterWithName:@"CIColorMatrix" keysAndValues:
                            kCIInputImageKey, inputImage,
                            @"inputRVector", [CIVector vectorWithX:0 Y:0 Z:0 W:0],          // Blank out r.
                            @"inputGVector", [CIVector vectorWithX:0 Y:0 Z:0 W:0],          // Blank out g.
                            @"inputBVector", [CIVector vectorWithX:0 Y:0 Z:0 W:0],          // Blank out b.
                            @"inputAVector", [CIVector vectorWithX:0 Y:0 Z:0 W:1],          // Leave alpha alone.
                            @"inputBiasVector", [CIVector vectorWithX:red Y:green Z:blue W:0], // Raise r, g, and b to desired color values.
                            nil].outputImage;

    //See: http://stackoverflow.com/a/15886422/135557
    CGImageRef imageRef    = [[CIContext contextWithOptions:nil] createCGImage:outputImage fromRect:outputImage.extent];
    UIImage* outputUIImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    return outputUIImage;
}

@end
