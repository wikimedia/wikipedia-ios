//
//  UIViewController+WMFEmptyView.h
//  Wikipedia
//
//  Created by Corey Floyd on 12/10/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSUInteger, WMFEmptyViewType) {
    WMFEmptyViewTypeNoFeed,
    WMFEmptyViewTypeArticleDidNotLoad,
    WMFEmptyViewTypeNoSearchResults,
    WMFEmptyViewTypeNoSavedPages,
    WMFEmptyViewTypeNoHistory
};

@interface UIViewController (WMFEmptyView)

- (void)wmf_showEmptyViewOfType:(WMFEmptyViewType)type;
- (void)wmf_hideEmptyView;

@end
