//  Created by Monte Hurd on 10/14/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIImage (WMFStyle)

+ (UIImage*)wmf_placeholderImage;

+ (instancetype)wmf_imageFromColor:(UIColor*)color;

// Can directly use 'imageFlippedForRightToLeftLayoutDirection' once iOS 8 is no longer supported.
- (UIImage*)wmf_imageFlippedForRTLLayoutDirectionIfAtLeastiOS9 WMF_DEPRECATED_WHEN_DEPLOY_AT_LEAST_9;

+ (UIImage*)wmf_imageFlippedForRTLLayoutDirectionNamed:(NSString*)name;

@end
