//  Created by Monte Hurd on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFWebViewFooterContainerView.h"

@implementation WMFWebViewFooterContainerView

- (void)layoutSubviews {
    [super layoutSubviews];
    static CGFloat lastHeight = -1;
    if (self.frame.size.height != lastHeight) {
        [self.delegate footerContainer:self heightChanged:self.frame.size.height];
        lastHeight = self.frame.size.height;
    }
}

@end
