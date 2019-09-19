#import <CoreGraphics/CGGeometry.h>
#import <CoreGraphics/CGAffineTransform.h>

///
/// @name Unit Conversions
///

#define RADIANS_TO_DEGREES(radians) ((radians)*180.0 / M_PI)

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

///
/// @name Aggregate Operations
///

/**
 * Convert `rect` from CoreGraphics to UIKit coordinate space, then normalize using `size`.
 *
 * This is provided as a convenience for situations where normalization and conversion is necessary, as manually
 * chaining calls to the corresponding functions (or concatenating transforms) can be tedious and problematic.
 *
 * @return A normalized rect in the UIKit coordinate space.
 */
extern CGRect WMFConvertAndNormalizeCGRectUsingSize(CGRect rect, CGSize size);

///
/// @name Normalization
///

/**
 * Normalize `rect` by dividing its dimensions by `size`.
 *
 * Can be used to convert a rectangle into the unit coordinate system (everything between [0,1]).
 *
 * @param rect The rectangle to convert.
 * @param size The dimensions to use during normalization.
 *
 * @return New `CGRect` whose origin and size have been normalized using the size of `bounds`.
 */
extern CGRect WMFNormalizeRectUsingSize(CGRect rect, CGSize size);

/**
 * Denormalize `rect` by multiplying its dimensions by `size`.
 *
 * Can be used to take a rectangle out of the unit coordinate system.
 *
 * @param rect The rectangle to convert.
 * @param size The dimensions to use during normalization.
 *
 * @return New `CGRect` whose origin and size have been normalized using the size of `bounds`.
 */
extern CGRect WMFDenormalizeRectUsingSize(CGRect rect, CGSize size);

///
/// @name Normalization Transforms
///

/**
 * @return A transform which will normalize rects to the given size.
 *
 * @warning Be careful when putting in chains of concatenated transforms, this one should probably go last.
 */
extern CGAffineTransform WMFAffineNormalizeTransformMake(CGSize size);

/**
 * @return A transform which will denormalize rects to the given size.
 *
 * @note Inverse of `WMFAffineNormalizeTransformMake`
 *
 * @warning Be careful when putting in chains of concatenated transforms, this one should probably go last.
 */
extern CGAffineTransform WMFAffineDenormalizeTransformMake(CGSize size);

///
/// @name Coordinate Space Conversions
///

/**
 * Convert `cgRect` from the Core Graphics coordinate system to UIKit coordinate system, using `size` as the bounds.
 *
 * @param cgRect The rect to convert, obtained from an environment that uses the CoreGraphics coordinate system.
 * @param size   The size of the bounds that `rect` resides in, for example the bounds of the containing view or image.
 *
 * @return A `CGRect` with the same size as `cgRect`, but whose origin is the UIKit-equivalent point.
 */
extern CGRect WMFConvertCGCoordinateRectToUICoordinateRectUsingSize(CGRect cgRect, CGSize size);

/**
 * Convert `uiRect` from the UIKit coordinate system to the CoreGraphics coordinate system, using `size` as the bounds.
 *
 * This is the inverse of `WMFConvertCGCoordinateRectToUICoordinateRectUsingSize`
 *
 * @return A `CGRect` with the same size as `uiRect`, but whose origin is the CoreGraphics-equivalent point.
 *
 * @see WMFConvertCGCoordinateRectToUICoordinateRectUsingSize
 */
extern CGRect WMFConvertUICoordinateRectToCGCoordinateRectUsingSize(CGRect uiRect, CGSize size);

///
/// @name Coordinate Space Conversion Transforms
///

/**
 * @return A transform which will convert rects from Core Graphics (y origin on the bottom) to UIKit (y origin on the
 *         top.
 */
extern CGAffineTransform WMFAffineUIKitToCoreGraphicsTransformMake(CGSize size);

/**
 * @return A transform which will convert rects from UIKit (y origin on the top) to Core Graphics (y origin on the
 *         bottom).
 *
 * @note Inverse of `WMFAffineUIKitToCoreGraphicsTransformMake`
 */
extern CGAffineTransform WMFAffineCoreGraphicsToUIKitTransformMake(CGSize size);


/**
* @return The distance between two points
*/
extern CGFloat WMFDistanceBetweenPoints(CGPoint a, CGPoint b);
