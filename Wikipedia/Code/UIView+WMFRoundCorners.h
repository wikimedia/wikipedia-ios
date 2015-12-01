//  Created by Monte Hurd on 11/10/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIView (WMF_RoundCorners)

/**
 * @warning Watch out for race conditions with auto layout when using these methods! Be sure to call them after layout,
 * e.g. in @c viewDidLayoutSubviews.
 */

/// Round all corners of the receiver, making it circular.
- (void)wmf_makeCircular;

/**
 * Round the given corners of the receiver.
 * @param corners   The corners to apply rounding to.
 * @param radius    The radius to apply to @c corners.
 */
- (void)wmf_roundCorners:(UIRectCorner)corners toRadius:(float)radius;

@end
