/* Unsafe, do not use.* @see WMFStrictClamp * @see WMFClamp */
#define _WMFStrictClamp(min, x, max) MAX(MIN((max), (x)), (min))

@import Foundation;

/**
 * @function WMFStrictClamp
 * Function-like macro which clamps `x` between `[min, max]` without defensively handling cases where `min > max`.
 *
 * Use this when passing literal values for `min` and `max`, e.g. `WMFStrictClamp(0, x, 10)`, or other scenarios where
 * `min <= max` is guaranteed to be true. This will eschew defensive bounds checks performed in `WMFClamp`.
 *
 * @param min The lower bound, must be less or equal to `max`.
 * @param x   The value to clamp.
 * @param max The upper bound, must be greater than or equal to `min`.
 *
 * @return The value passed to the `x` parameter, bounded between `[min, max]`.
 *
 * @see WMFClamp
 */
#define WMFStrictClamp(min, x, max) (NO, (void)assert((min) < (max)), _WMFStrictClamp((min), (x), (max)))

/**
 * @function WMFClamp
 * Function-like macro which will clamp `x` between `[b1, b2]` (or `[b2, b1]` if `b2 < b1`).
 *
 * @param b1  One of the bounds to clamp to, convention is to make `b1` the lower bound.
 * @param x   The value to be clamped between `min` & `max` (inclusive).
 * @param b2  The other bound to clamp to, convention is to make `b2` the upper bound.
 *
 * Example usage: `WMFClamp(0, x, 2)` will ensure that `x` is between `0` and `2`. This is equivalent to
 * `WMFClamp(2, x, 0)`.
 *
 * @return The value passed to the `x` parameter, clamped between the given bounds, `b1` and `b2`.
 */
#define WMFClamp(b1, x, b2) WMFStrictClamp(MIN((b1), (b2)), (x), MAX((b1), (b2)))

/**
 * Round @c x to @c precision using the @c rounder function.
 * @param rounder   Function which rounds a given number.
 * @param x         The number to round.
 * @param precision The number of significant digits to round to after the decimal point.
 */
extern double RoundWithPrecision(double (*rounder)(double), double x, unsigned int precision);

/**
 *  Round @c x to 2 significant digits after the decimal point.
 *
 *  @param x Number to round.
 *
 *  @return @c x rounded to 2 decimal points.
 */
extern double WMFFlooredPercentage(double x) __attribute__((const)) __attribute__((pure));

/**
 *  Convert angle in radians into hours on a clockface.
 *
 *  If we imagine a clockface instead of a unit circle (the hour 12 is aligned with 0 radians),
 *  then we set the clock pointer to the given the degree, this function returns the number
 *  of the nearest hour.
 *
 *  @param radians Angle in radians
 *
 *  @return NSInteger representing the corresponding reading on the clockface.
 */

NSInteger WMFRadiansToClock(double radians);

///
/// @name Geometry
///

/**
 *  Convert a number of Megabytes into the corresponding number of bytes.
 *  @param m The number of Megabytes to convert into bytes.
 *  @return Number of bytes equivalent to `m` megabytes.
 */
static inline NSUInteger MegabytesToBytes(NSUInteger m) {
    static NSUInteger const MEGABYTE = 1 << 20;
    return m * MEGABYTE;
}
