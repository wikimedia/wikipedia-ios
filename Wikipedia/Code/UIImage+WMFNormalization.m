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

- (NSArray<NSValue *> *)wmf_normalizeAndConvertBoundsFromCIFeatures:(NSArray<CIFeature *> *)features {
    return [features wmf_map:^NSValue *(CIFeature *feature) {
        return [NSValue valueWithCGRect:[self wmf_normalizeAndConvertCGCoordinateRect:feature.bounds]];
    }];
}

@end
