#import "UIViewController+WMFEmptyView.h"
#import "WMFEmptyView.h"
#import <objc/runtime.h>
@implementation UIViewController (WMFEmptyView)

static const char *const WMFEmptyViewKey = "WMFEmptyView";

- (UIView *)wmf_emptyView {
    return objc_getAssociatedObject(self, WMFEmptyViewKey);
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

    objc_setAssociatedObject(self, WMFEmptyViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)wmf_hideEmptyView {
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        [(UIScrollView *)self.view setScrollEnabled:YES];
    }
    UIView *view = [self wmf_emptyView];
    [view removeFromSuperview];

    objc_setAssociatedObject(self, WMFEmptyViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)wmf_isShowingEmptyView {
    return [self wmf_emptyView].superview != nil;
}

@end
