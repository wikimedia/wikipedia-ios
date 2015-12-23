//
//  UIViewController+WMFEmptyView.m
//  Wikipedia
//
//  Created by Corey Floyd on 12/10/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIViewController+WMFEmptyView.h"
#import "WMFEmptyView.h"
#import <Masonry/Masonry.h>

@implementation UIViewController (WMFEmptyView)

static NSString * WMFEmptyViewKey = @"WMFEmptyView";

- (UIView*)wmf_emptyView {
    return [self bk_associatedValueForKey:CFBridgingRetain(WMFEmptyViewKey)];
}

- (void)wmf_showEmptyViewOfType:(WMFEmptyViewType)type {
    [self wmf_hideEmptyView];

    UIView* view = nil;
    switch (type) {
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
    }

    UIView* container = self.view.superview;
    if ([container isKindOfClass:[UIScrollView class]]) {
        container = container.superview;
    }
    NSAssert(container != nil, @"Trying to add an empty view with no container view");
    if (!container) {
        return;
    }

    if ([self.view isKindOfClass:[UIScrollView class]]) {
        [(UIScrollView*)self.view setScrollEnabled:NO];
    }
    [self.view addSubview:view];

    [view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.top.equalTo(container);
        make.bottom.equalTo(container);
        make.leading.and.trailing.equalTo(container);
    }];
    [self bk_associateValue:view withKey:CFBridgingRetain(WMFEmptyViewKey)];
}

- (void)wmf_hideEmptyView {
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        [(UIScrollView*)self.view setScrollEnabled:YES];
    }
    UIView* view = [self wmf_emptyView];
    [view removeFromSuperview];
    [self bk_associateValue:nil withKey:CFBridgingRetain(WMFEmptyViewKey)];
}

@end
