@import UIKit;

@interface UIImage (WMFNormalization)

/**
 * Normalize `rect` using the receiver's size.
 *
 * @param rect The rect to normalize.
 *
 * @return A normalized `CGRect`.
 *
 * @see WMFNormalizeRectUsingSize
 */
- (CGRect)wmf_normalizeRect:(CGRect)rect;

/**
 * Denormalize `rect` using the receiver's size.
 *
 * @param rect The rect to denormalize.
 *
 * @return A denormalized `CGRect`.
 *
 * @see WMFDenormalizeRectUsingSize
 */
- (CGRect)wmf_denormalizeRect:(CGRect)rect;

/**
 * Convert the bounds of the given feature into UIKit coordinate space, then normalize it using the receiver's size.
 *
 * @param rect The rect to be normalized, e.g. the bounds of a `CIFeature`.
 *
 * @return A normalized `CGRect` in the UIKit coordinate space.
 *
 * @see WMFConvertUIKitCoordinateRectToCGCoordinateRectUsingSize
 */
- (CGRect)wmf_normalizeAndConvertCGCoordinateRect:(CGRect)rect;

/**
 * Convert the bounds of each given feature into UIKit coordinate space, then normalize it using the receiver's size.
 *
 * @param features The array of features to be normalized
 *
 * @return An array of normalized `CGRect`s wrapped in `NSValue`s in the UIKit coordinate space.
 *
 * @see wmf_normalizeAndConvertCGCoordinateRect
 */
- (NSArray<NSValue *> *)wmf_normalizeAndConvertBoundsFromCIFeatures:(NSArray<CIFeature *> *)features;

@end
