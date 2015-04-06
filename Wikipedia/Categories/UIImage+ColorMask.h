//  Created by Monte Hurd and Adam Baso on 2/13/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIImage (ColorMask)

// Pass this method a color and it will return an image based on this image
// but with any parts which were not transparent changed to be "color". This is
// handier that it sounds for fine-tuning the appearance of button images without
// the need for regenerating new pngs. Because of the way the filter is set
// up below, this method can be called repeatedly w/no image quality degradation.
// Intended for use with images which don't have gradients / shadows.
- (UIImage*)getImageOfColor:(CGColorRef)CGColor;

@end
