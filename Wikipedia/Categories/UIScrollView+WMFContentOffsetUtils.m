//
//  UIScrollView+WMFContentOffsetUtils.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIScrollView+WMFContentOffsetUtils.h"

@implementation UIScrollView (WMFContentOffsetUtils)

- (CGPoint)wmf_topContentOffset {
    return CGPointMake(self.contentInset.left, self.contentInset.top);
}

- (void)wmf_scrollToTop:(BOOL)animated {
    [self setContentOffset:self.wmf_topContentOffset animated:animated];
}

- (CGRect)wmf_contentFrame {
    return UIEdgeInsetsInsetRect(CGRectOffset(self.frame, 0, self.contentOffset.y), self.contentInset);
}

- (void)wmf_safeSetContentOffset:(CGPoint)offset animated:(BOOL)animated {
    if (offset.x == offset.x && offset.y == offset.y) {
        if (self.contentSize.width < offset.x || self.contentSize.height < offset.y) {
            DDLogWarn(@"Attempting to scroll to offset %@ which exceeds contentSize scroll view %@",
                      NSStringFromCGPoint(offset), self);
        }
        [self setContentOffset:offset animated:animated];
    } else {
        DDLogError(@"Ignoring invalid offset %@ for scroll view %@", NSStringFromCGPoint(offset), self);
    }
}

@end
