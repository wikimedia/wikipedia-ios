#import "UIScrollView+ScrollSubviewToLocation.h"

@implementation UIScrollView (ScrollSubviewToLocation)

- (void)scrollSubviewToTop:(UIView *)subview animated:(BOOL)animated {
    [self scrollSubviewToTop:subview offset:0 animated:animated];
}

- (void)scrollSubviewToTop:(UIView *)subview offset:(CGFloat)offset animated:(BOOL)animated {
    // Find the scroll view's subview location in the scroll view's superview coordinates.
    CGPoint locationInSuperview = [subview convertPoint:CGPointZero toView:self.superview];
    // Determine how far the scroll view will need to be scrolled to move the subview's top
    // just beneath the navigation bar.
    CGFloat yOffset = self.contentOffset.y + (locationInSuperview.y - self.scrollIndicatorInsets.top) - offset;
    // Scroll!
    [self setContentOffset:CGPointMake(self.contentOffset.x, yOffset) animated:animated];
}

@end
