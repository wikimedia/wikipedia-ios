//
//  UIImage+WMFImageProcessing.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIImage+WMFImageProcessing.h"

@implementation UIImage (WMFImageProcessing)

- (CIImage *__nonnull)wmf_getOrCreateCIImage {
    return self.CIImage ?: [[CIImage alloc] initWithCGImage:self.CGImage];
}

@end
