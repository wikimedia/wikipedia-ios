//  Created by Monte Hurd on 10/14/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIImage+WMFStyle.h"

@implementation UIImage (WMFStyle)

+(UIImage*)wmf_placeholderImage {
    static UIImage* img;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        img = [[UIImage imageNamed:@"image-placeholder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return img;
}

@end
