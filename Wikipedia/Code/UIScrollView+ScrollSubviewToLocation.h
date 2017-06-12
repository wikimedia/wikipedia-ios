@import UIKit;

@interface UIScrollView (ScrollSubviewToLocation)

- (void)scrollSubViewToTop:(UIView *)subview animated:(BOOL)animated;

- (void)scrollSubViewToTop:(UIView *)subview offset:(CGFloat)offset animated:(BOOL)animated;

@end
