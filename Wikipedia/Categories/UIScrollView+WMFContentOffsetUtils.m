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
    return CGRectOffset(self.frame, 0, self.contentOffset.y);
}

@end
