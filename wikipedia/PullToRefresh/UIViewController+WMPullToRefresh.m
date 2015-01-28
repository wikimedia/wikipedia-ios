
#import "UIViewController+WMPullToRefresh.h"
#import "WMPullToRefreshContentView.h"
#import "Masonry.h"

@import ObjectiveC;

static NSString* const kPullToRefreshView = @"kPullToRefreshView";

@implementation UIViewController (WMPullToRefresh)

@dynamic refreshPromptString;
@dynamic refreshReleaseString;
@dynamic refreshRunningString;

- (void)setupPullToRefreshWithType:(WMPullToRefreshProgressType)type inScrollView:(UIScrollView*)scrollView{

    SSPullToRefreshView* pullToRefresh = [self pullToRefreshView];
    
    if(pullToRefresh){
        
        [self tearDownPullToRefresh];
    }

    pullToRefresh = [[SSPullToRefreshView alloc] initWithScrollView:scrollView delegate:(id<SSPullToRefreshViewDelegate>)self];
    
    objc_setAssociatedObject(self, (__bridge const void *)(kPullToRefreshView), pullToRefresh, OBJC_ASSOCIATION_RETAIN);

    [self setPullToRefreshContentView:[[WMPullToRefreshContentView alloc] initWithFrame:CGRectZero type:type]];
    
}

- (SSPullToRefreshView*)pullToRefreshView{
    
    return objc_getAssociatedObject(self, (__bridge const void *)(kPullToRefreshView));
}

- (WMPullToRefreshContentView*)pullToRefreshContentView{
    
    return (WMPullToRefreshContentView*)[self pullToRefreshView].contentView;
}

- (void)setPullToRefreshContentView:(WMPullToRefreshContentView*)contentView{
    
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self pullToRefreshView].contentView = contentView;
    
    [contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.equalTo(contentView.superview);
    }];

}

- (void)setRefreshProgress:(float)progress animated:(BOOL)animated{

    [[self pullToRefreshContentView] setProgress:progress animated:animated];
}


- (void)finishRefreshing{

    if([[self pullToRefreshContentView] isAnimatingProgress]){
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self finishRefreshing];
        });
        return;
    }
    
     [[self pullToRefreshView] finishLoading];
}


- (void)tearDownPullToRefresh{
 
    [[self pullToRefreshView] removeFromSuperview];
    
    objc_setAssociatedObject(self, (__bridge const void *)(kPullToRefreshView), nil, OBJC_ASSOCIATION_RETAIN);

}

#pragma mark - Forward string configuration to content view

- (id)forwardingTargetForSelector:(SEL)aSelector{
    
    if(sel_isEqual(aSelector, @selector(setRefreshPromptString:)) ||
       sel_isEqual(aSelector, @selector(refreshPromptString)) ||
       sel_isEqual(aSelector, @selector(setRefreshReleaseString:)) ||
       sel_isEqual(aSelector, @selector(refreshReleaseString)) ||
       sel_isEqual(aSelector, @selector(setRefreshRunningString:)) ||
       sel_isEqual(aSelector, @selector(refreshRunningString)) ||
       sel_isEqual(aSelector, @selector(setRefreshCancelBlock:)) ||
       sel_isEqual(aSelector, @selector(refreshCancelBlock))
       ){
        
        return [self pullToRefreshContentView];
    }
    
    return [super forwardingTargetForSelector:aSelector];
}

@end

