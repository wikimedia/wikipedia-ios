//
//  WMPullToRefreshView+WMDefault.m
//  Wikipedia
//
//  Created by Corey Floyd on 1/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMPullToRefreshView+WMDefault.h"
#import "WMPullToRefreshContentView.h"
#import <Masonry/Masonry.h>

@implementation WMPullToRefreshView (WMDefault)

+ (WMPullToRefreshView*)defaultIndeterminateProgressViewWithScrollView:(UIScrollView *)scrollView delegate:(id<WMPullToRefreshViewDelegate>)delegate{
    
    WMPullToRefreshView* pullToRefresh = [[WMPullToRefreshView alloc] initWithScrollView:scrollView delegate:delegate];
    [pullToRefresh setContentView:[[WMPullToRefreshContentView alloc] initWithFrame:CGRectZero type:WMPullToRefreshProgressTypeIndeterminate]];
    
    pullToRefresh.pullStyle = WMPullToRefreshPullStyleDistance;
    
    [pullToRefresh.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.equalTo(pullToRefresh);
    }];
    
    return pullToRefresh;
}

+ (WMPullToRefreshView*)defaultDeterminateProgressViewWithScrollView:(UIScrollView *)scrollView delegate:(id<WMPullToRefreshViewDelegate>)delegate{
    
    WMPullToRefreshView* pullToRefresh = [[WMPullToRefreshView alloc] initWithScrollView:scrollView delegate:delegate];
    [pullToRefresh setContentView:[[WMPullToRefreshContentView alloc] initWithFrame:CGRectZero type:WMPullToRefreshProgressTypeDeterminate]];
    
    pullToRefresh.pullStyle = WMPullToRefreshPullStyleDistance;
    
    [pullToRefresh.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.equalTo(pullToRefresh);
    }];
    
    return pullToRefresh;
}

- (WMPullToRefreshContentView*)defaultContentView{
    
    if(![self.contentView isKindOfClass:[WMPullToRefreshContentView class]])
        return nil;
    
    return (WMPullToRefreshContentView*)[self contentView];
}



@end
