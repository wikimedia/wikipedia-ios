#import "UIViewController+WMFEmptyView.h"
#import "WMFEmptyView.h"
#import <objc/runtime.h>
@import WMF.Swift;

@implementation UIViewController (WMFEmptyView)

static const char *const WMFEmptyViewKey = "WMFEmptyView";

- (nullable WMFEmptyView *)wmf_emptyView {
    return objc_getAssociatedObject(self, WMFEmptyViewKey);
}

- (void)wmf_showEmptyViewOfType:(WMFEmptyViewType)type theme:(WMFTheme *)theme frame:(CGRect)frame {
    [self wmf_hideEmptyView];

    WMFEmptyView *view = nil;
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
        case WMFEmptyViewTypeNoSavedPagesInReadingList:
            view = [WMFEmptyView noSavedPagesInReadingListEmptyView];
            break;
        case WMFEmptyViewTypeNoHistory:
            view = [WMFEmptyView noHistoryEmptyView];
            break;
        case WMFEmptyViewTypeNoReadingLists:
            view = [WMFEmptyView noReadingListsEmptyView];
            break;
        default:
            return;
    }
    [view applyTheme:theme];

    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.frame = frame;

    if ([self.view isKindOfClass:[UIScrollView class]]) {
        [(UIScrollView *)self.view setScrollEnabled:NO];
    }

    objc_setAssociatedObject(self, WMFEmptyViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (!view) {
        return;
    }

    if ([self conformsToProtocol:@protocol(WMFEmptyViewContainer)]) {
        [(id)self addEmptyView:view];
    } else {
        [self.view addSubview:view];
    }
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

- (void)wmf_applyThemeToEmptyView:(WMFTheme *)theme {
    [[self wmf_emptyView] applyTheme:theme];
}

- (void)wmf_setEmptyViewFrame:(CGRect)frame {
    [[self wmf_emptyView] setFrame:frame];
}

@end
