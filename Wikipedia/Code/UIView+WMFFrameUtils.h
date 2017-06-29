@import UIKit;

FOUNDATION_EXPORT CGPoint WMFCenterOfCGSize(CGSize size) __attribute__((const)) __attribute__((pure));

@interface UIView (WMFFrameUtils)

/// Sets the receiver's @c frame.origin, preserving its @c size.
- (void)wmf_setFrameOrigin:(CGPoint)origin;

/// Sets the receiver's @c frame.size, preserving its @c origin.
- (void)wmf_setFrameSize:(CGSize)size;

/// Sets the receiver's @c frame by applying @c CGRectInset() with @c width as @c dx and @c height as @c dy.
- (void)wmf_insetWidth:(float)width height:(float)height;

/**
 * Expand the receiver's frame while preserving its center by @c padding.
 * @discussion This method behaves identical to inset, but positive values grow the frame, rather than shrink it.
 * @see -wmf_insetWidth:height:
 * @see CGRectInset()
 */
- (void)wmf_expandWidth:(float)width height:(float)height;

- (void)wmf_centerInSuperview;

@end
