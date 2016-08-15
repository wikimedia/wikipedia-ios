#import <UIKit/UIKit.h>

@interface UIImage (WMFStyle)

+ (UIImage *)wmf_placeholderImage;

+ (instancetype)wmf_imageFromColor:(UIColor *)color;

// Can directly use 'imageFlippedForRightToLeftLayoutDirection' once iOS 8 is no
// longer supported.
- (UIImage *)wmf_imageFlippedForRTLLayoutDirectionIfAtLeastiOS9
    WMF_DEPRECATED_WHEN_DEPLOY_AT_LEAST_9;

+ (UIImage *)wmf_imageFlippedForRTLLayoutDirectionNamed:(NSString *)name;

@end
