//  Created by Monte Hurd on 4/2/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIScrollView+NoHorizontalScrolling.h"

@implementation UIScrollView (NoHorizontalScrolling)

- (void)preventHorizontalScrolling {
    CGSize widthRestrictedContentSize = CGSizeMake(self.superview.frame.size.width, self.contentSize.height);
    if (!CGSizeEqualToSize(self.contentSize, widthRestrictedContentSize)) {
        [self setContentSize:widthRestrictedContentSize];
    }
}

@end
