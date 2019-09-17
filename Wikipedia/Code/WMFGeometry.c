#import <WMF/WMFGeometry.h>
#include <CoreGraphics/CGAffineTransform.h>
#include "math.h"

#pragma mark - Aggregate Operations

CGRect WMFConvertAndNormalizeCGRectUsingSize(CGRect rect, CGSize size) {
    CGAffineTransform normalizeAndConvertTransform =
        CGAffineTransformConcat(WMFAffineCoreGraphicsToUIKitTransformMake(size),
                                WMFAffineNormalizeTransformMake(size));
    return CGRectApplyAffineTransform(rect, normalizeAndConvertTransform);
}

#pragma mark - Normalization

CGRect WMFNormalizeRectUsingSize(CGRect rect, CGSize size) {
    if (CGSizeEqualToSize(size, CGSizeZero) || CGRectIsEmpty(rect)) {
        return CGRectZero;
    }
    return CGRectApplyAffineTransform(rect, WMFAffineNormalizeTransformMake(size));
}

CGRect WMFDenormalizeRectUsingSize(CGRect rect, CGSize size) {
    if (CGSizeEqualToSize(size, CGSizeZero) || CGRectIsEmpty(rect)) {
        return CGRectZero;
    }
    return CGRectApplyAffineTransform(rect, WMFAffineDenormalizeTransformMake(size));
}

#pragma mark - Normalization Transforms

CGAffineTransform WMFAffineNormalizeTransformMake(CGSize size) {
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        return CGAffineTransformIdentity;
    }
    return CGAffineTransformMakeScale(1.0f / size.width, 1.0f / size.height);
}

CGAffineTransform WMFAffineDenormalizeTransformMake(CGSize size) {
    return CGAffineTransformInvert(WMFAffineNormalizeTransformMake(size));
}

#pragma mark - Coordinate System Conversions

CGRect WMFConvertCGCoordinateRectToUICoordinateRectUsingSize(CGRect cgRect, CGSize size) {
    return CGRectApplyAffineTransform(cgRect, WMFAffineCoreGraphicsToUIKitTransformMake(size));
}

CGRect WMFConvertUICoordinateRectToCGCoordinateRectUsingSize(CGRect uiRect, CGSize size) {
    return CGRectApplyAffineTransform(uiRect, WMFAffineUIKitToCoreGraphicsTransformMake(size));
}

#pragma mark - Coordinate System Conversion Transforms

CGAffineTransform WMFAffineCoreGraphicsToUIKitTransformMake(CGSize size) {
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        return CGAffineTransformIdentity;
    }
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    return CGAffineTransformTranslate(transform, 0, -size.height);
}

CGAffineTransform WMFAffineUIKitToCoreGraphicsTransformMake(CGSize size) {
    return CGAffineTransformInvert(WMFAffineCoreGraphicsToUIKitTransformMake(size));
}

#pragma mark - Distance

CGFloat WMFDistanceBetweenPoints(CGPoint a, CGPoint b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
}
