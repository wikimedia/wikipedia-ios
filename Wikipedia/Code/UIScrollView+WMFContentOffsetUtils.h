@import UIKit;

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

@end
