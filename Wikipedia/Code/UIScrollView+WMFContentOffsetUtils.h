//
//  UIScrollView+WMFContentOffsetUtils.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (WMFContentOffsetUtils)

/**
 *  @return The offset at which the receiver would rest after scrolling to the top.
 */
- (CGPoint)wmf_topContentOffset;

/**
 *  Scroll the receiver to the top of its content.
 *
 *  Use this instead of setting `contentOffset = CGPointZero`, as some scroll views have `contentInset != CGPointZero`.
 *
 *  @see wmf_topContentOffset
 */
- (void)wmf_scrollToTop:(BOOL)animated;

/**
 *  The frame representing the visible area of the receiver's content.
 *
 *  Incorporates the receiver's @c contentOffset and @c contentInset, ensuring that any content offscreen or under
 *  elements assumed to be taken up by @c contentInset are outside the returned @c CGRect.
 *
 *  @return A @c CGRect describing the origin and size of the visible content.
 */
- (CGRect)wmf_contentFrame;


/**
 *  Set offset if within bounds and valid (i.e. not NaN).
 *
 *  Use this when setting offsets that might have invalid values, e.g. those obtained from the
 *  web view.
 *
 *  @param offset   The offset to apply.
 *  @param animated Whether or not to animate scrolling to given offset.
 *
 *  @see setContentOffset:animated:
 */
- (void)wmf_safeSetContentOffset:(CGPoint)offset animated:(BOOL)animated;

@end
