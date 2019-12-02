@import UIKit;

@interface UIScrollView (ScrollSubviewToLocation)

- (void)scrollSubviewToTop:(UIView *)subview animated:(BOOL)animated;

- (void)scrollSubviewToTop:(UIView *)subview offset:(CGFloat)offset animated:(BOOL)animated;

@end
