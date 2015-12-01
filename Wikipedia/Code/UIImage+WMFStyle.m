//  Created by Monte Hurd on 10/14/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIImage+WMFStyle.h"

@implementation UIImage (WMFStyle)

+ (UIImage*)wmf_placeholderImage {
    static UIImage* img;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        img = [[UIImage imageNamed:@"image-placeholder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return img;
}

+ (instancetype)wmf_imageFromColor:(UIColor*)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
