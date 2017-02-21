#import <UIKit/UIKit.h>

@interface UIScrollView (ScrollSubviewToLocation)

- (void)scrollSubViewToTop:(UIView *)subview animated:(BOOL)animated;

- (void)scrollSubViewToTop:(UIView *)subview offset:(CGFloat)offset animated:(BOOL)animated;

@end
