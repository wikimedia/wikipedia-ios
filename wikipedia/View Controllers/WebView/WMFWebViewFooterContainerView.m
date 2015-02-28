//  Created by Monte Hurd on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFWebViewFooterContainerView.h"

@interface WMFWebViewFooterContainerView()

@property (nonatomic) CGFloat height;

@end

@implementation WMFWebViewFooterContainerView

- (instancetype)initWithHeight:(CGFloat)height
{
    self = [super init];
    if (self) {
        self.height = height;
        self.backgroundColor = [UIColor lightGrayColor];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, self.height);
}

@end
