//  Created by Monte Hurd on 8/7/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIButton+WMFMultiLineHeight.h"

@implementation UIButton (WMFMultiLineHeight)

- (CGFloat)wmf_heightAccountingForMultiLineText {
    return
        [self.titleLabel sizeThatFits:self.superview.frame.size].height +
        self.contentEdgeInsets.top +
        self.contentEdgeInsets.bottom +
        self.titleEdgeInsets.top +
        self.titleEdgeInsets.bottom;
}

@end
