#import "UIScrollView+WMFContentOffsetUtils.h"
@import WMF.WMFLogging;

@implementation UIScrollView (WMFContentOffsetUtils)

- (CGPoint)wmf_topContentOffset {
    return CGPointMake(0 - self.contentInset.left, 0 - self.contentInset.top);
}

- (void)wmf_scrollToTop:(BOOL)animated {
    [self setContentOffset:self.wmf_topContentOffset animated:animated];
}

- (CGRect)wmf_contentFrame {
    return UIEdgeInsetsInsetRect(CGRectOffset(self.frame, 0, self.contentOffset.y), self.contentInset);
}

@end
