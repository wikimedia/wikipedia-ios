//
//  UIImage+WMFNormalization.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIImage+WMFNormalization.h"
#import "WMFGeometry.h"

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
    return [features bk_map:^NSValue *(CIFeature *feature) {
      return [NSValue valueWithCGRect:[self wmf_normalizeAndConvertCGCoordinateRect:feature.bounds]];
    }];
}

@end
