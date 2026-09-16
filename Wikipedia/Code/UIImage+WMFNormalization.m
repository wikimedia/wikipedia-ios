#import "UIImage+WMFNormalization.h"
#import <WMF/WMF-Swift.h>

@implementation UIImage (WMFNormalization)

- (CGRect)wmf_normalizeRect:(CGRect)rect {
    return WMFNormalizeRectUsingSize(rect, self.size);
}

- (CGRect)wmf_denormalizeRect:(CGRect)rect {
    return WMFDenormalizeRectUsingSize(rect, self.size);
}

- (CGRect)wmf_normalizeAndConvertCGCoordinateRect:(CGRect)rect {
    return WMFConvertAndNormalizeCGRectUsingSize(rect, self.size);
}

@end
