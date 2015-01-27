
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

    switch (type) {
        case WMPullToRefreshProgressTypeIndeterminate:
            [self setPullToRefreshContentView:[UIViewController standardPullToRefreshContentView]];
            break;
        case WMPullToRefreshProgressTypeDeterminate:
            [self setPullToRefreshContentView:[UIViewController progressPullToRefreshContentView]];
            break;
        default:
            break;
    }
    

}

- (SSPullToRefreshView*)pullToRefreshView{
    
    return objc_getAssociatedObject(self, (__bridge const void *)(kPullToRefreshView));
}

- (UIView<WMPullToRefreshContentView>*)pullToRefreshContentView{
    
    return (UIView<WMPullToRefreshContentView>*)[self pullToRefreshView].contentView;
}

- (void)setPullToRefreshContentView:(UIView<SSPullToRefreshContentView>*)contentView{
    
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self pullToRefreshView].contentView = contentView;
    
    [contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.bottom.equalTo(contentView.superview).with.offset(-5.0);
        make.centerX.equalTo(contentView.superview);
    }];

}


- (void)finishRefreshing{
    
     [[self pullToRefreshView] finishLoading];
}


- (void)tearDownPullToRefresh{
 
    [[self pullToRefreshView] removeFromSuperview];
    
    objc_setAssociatedObject(self, (__bridge const void *)(kPullToRefreshView), nil, OBJC_ASSOCIATION_RETAIN);

}

#pragma mark - Forward string configuration to

- (id)forwardingTargetForSelector:(SEL)aSelector{
    
    NSString* selectorString = NSStringFromSelector(aSelector);
    
    if([selectorString isEqualToString:@"setRefreshPromptString:"] ||
       [selectorString isEqualToString:@"setRefreshReleaseString:"] ||
       [selectorString isEqualToString:@"setRefreshRunningString:"] ||
       [selectorString isEqualToString:@"refreshPromptString"] ||
       [selectorString isEqualToString:@"refreshReleaseString"] ||
       [selectorString isEqualToString:@"refreshRunningString"]
       ){
        
        return [self pullToRefreshContentView];
    }
    
    return [super forwardingTargetForSelector:aSelector];
}


#pragma mark - Create new content views

+ (UIView<WMPullToRefreshContentView>*)standardPullToRefreshContentView{
 
    return [[WMPullToRefreshContentView alloc] initWithFrame:CGRectZero];
}

+ (UIView<WMPullToRefreshContentView>*)progressPullToRefreshContentView{
    
    return [[WMPullToRefreshContentView alloc] initWithFrame:CGRectZero];
}


@end
