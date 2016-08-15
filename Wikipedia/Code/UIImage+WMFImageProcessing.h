//
//  UIImage+WMFImageProcessing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (WMFImageProcessing)

/// @return The receiver's existing `CIImage` property, or a new `CIImage` initialized with the receiver.
- (CIImage *__nonnull)wmf_getOrCreateCIImage;

@end
