//
//  WMPullToRefreshView+WMDefault.h
//  Wikipedia
//
//  Created by Corey Floyd on 1/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMPullToRefreshView.h"
#import "WMPullToRefreshContentView.h"

@interface WMPullToRefreshView (WMDefault)

+ (WMPullToRefreshView*)defaultIndeterminateProgressViewWithScrollView:(UIScrollView *)scrollView delegate:(id<WMPullToRefreshViewDelegate>)delegate;

+ (WMPullToRefreshView*)defaultDeterminateProgressViewWithScrollView:(UIScrollView *)scrollView delegate:(id<WMPullToRefreshViewDelegate>)delegate;

- (WMPullToRefreshContentView*)defaultContentView;

@end
