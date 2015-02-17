//  Created by Monte Hurd on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewBottomTrackingContainerView.h"

@interface WebViewBottomTrackingContainerView()

@property (nonatomic) CGFloat height;

@end

@implementation WebViewBottomTrackingContainerView

- (instancetype)initWithHeight:(CGFloat)height
{
    self = [super init];
    if (self) {
        self.height = height;
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, self.height);
}

@end
