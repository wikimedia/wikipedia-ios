#import "UIViewController+WMFEmptyView.h"
#import "WMFEmptyView.h"

@implementation UIViewController (WMFEmptyView)

static NSString *WMFEmptyViewKey = @"WMFEmptyView";

- (UIView *)wmf_emptyView {
    id valueToReturn = [self bk_associatedValueForKey:(__bridge const void *)(WMFEmptyViewKey)];

    return valueToReturn;
}

- (void)wmf_showEmptyViewOfType:(WMFEmptyViewType)type {
    [self wmf_hideEmptyView];

    UIView *view = nil;
    switch (type) {
        case WMFEmptyViewTypeBlank:
            view = [WMFEmptyView blankEmptyView];
            break;
        case WMFEmptyViewTypeNoFeed:
            view = [WMFEmptyView noFeedEmptyView];
            break;
        case WMFEmptyViewTypeArticleDidNotLoad:
            view = [WMFEmptyView noArticleEmptyView];
            break;
        case WMFEmptyViewTypeNoSearchResults:
            view = [WMFEmptyView noSearchResultsEmptyView];
            break;
        case WMFEmptyViewTypeNoSavedPages:
            view = [WMFEmptyView noSavedPagesEmptyView];
            break;
        case WMFEmptyViewTypeNoHistory:
            view = [WMFEmptyView noHistoryEmptyView];
            break;
        default:
            return;
    }

    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.frame = self.view.bounds;

    if ([self.view isKindOfClass:[UIScrollView class]]) {
        [(UIScrollView *)self.view setScrollEnabled:NO];
    }
    [self.view addSubview:view];

    [self bk_associateValue:view withKey:(__bridge const void *)(WMFEmptyViewKey)];
}

- (void)wmf_hideEmptyView {
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        [(UIScrollView *)self.view setScrollEnabled:YES];
    }
    UIView *view = [self wmf_emptyView];
    [view removeFromSuperview];

    [self bk_associateValue:nil withKey:(__bridge const void *)(WMFEmptyViewKey)];
}

- (BOOL)wmf_isShowingEmptyView {
    return [self wmf_emptyView].superview != nil;
}

@end
