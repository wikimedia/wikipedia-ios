@import UIKit;

@interface UIColor (WMFStyle)

- (instancetype)wmf_copyWithAlpha:(CGFloat)alpha;

/**
 *  @return A dimmed copy of the receiver.
 *
 *  @see -wmf_colorByScalingComponents:
 */
- (instancetype)wmf_colorByApplyingDim;

/**
 *  @return A copy of the receiver, applying @c amount as a scalar to its red, green, blue, and alpha values.
 */
- (instancetype)wmf_colorByScalingComponents:(CGFloat)amount;

@end
