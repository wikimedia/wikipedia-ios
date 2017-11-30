@import UIKit;
@class WMFTheme;
@class WMFEmptyView;

typedef NS_ENUM(NSUInteger, WMFEmptyViewType) {
    WMFEmptyViewTypeNone,
    WMFEmptyViewTypeBlank,
    WMFEmptyViewTypeNoFeed,
    WMFEmptyViewTypeArticleDidNotLoad,
    WMFEmptyViewTypeNoSearchResults,
    WMFEmptyViewTypeNoSavedPages,
    WMFEmptyViewTypeNoHistory,
    WMFEmptyViewTypeNoReadingLists
};

@interface UIViewController (WMFEmptyView)

- (void)wmf_showEmptyViewOfType:(WMFEmptyViewType)type theme:(WMFTheme *)theme;
- (void)wmf_hideEmptyView;
- (BOOL)wmf_isShowingEmptyView;

@property (nonatomic, readonly) WMFEmptyView *wmf_emptyView;

@end
