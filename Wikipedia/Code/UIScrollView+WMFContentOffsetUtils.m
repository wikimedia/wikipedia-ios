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

- (void)wmf_safeSetContentOffset:(CGPoint)offset animated:(BOOL)animated completion:(void (^__nullable)(BOOL finished))completion {
    if (!isnan(offset.x) && !isinf(offset.x) && !isnan(offset.y) && !isinf(offset.y)) {
#if DEBUG
        // log warning, but still scroll, if we get an out-of-bounds offset
        if (self.contentSize.width < offset.x || self.contentSize.height < offset.y) {
            DDLogDebug(@"Attempting to scroll to offset %@ which exceeds contentSize scroll view %@",
                       NSStringFromCGPoint(offset), self);
        }
#endif
        [UIView animateWithDuration:(animated ? 0.3f : 0.0f)
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             CGPoint safeOffset = CGPointMake(offset.x, MAX(0 - self.contentInset.top, MIN(self.contentSize.height - self.bounds.size.height, offset.y)));

                             self.contentOffset = safeOffset;
                         }
                         completion:completion];
    } else {
        DDLogError(@"Ignoring invalid offset %@ for scroll view %@", NSStringFromCGPoint(offset), self);
        if (completion) {
            completion(NO);
        }
    }
}

@end
