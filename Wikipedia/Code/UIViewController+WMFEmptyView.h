
typedef NS_ENUM(NSUInteger, WMFEmptyViewType) {
    WMFEmptyViewTypeNone,
    WMFEmptyViewTypeBlank,
    WMFEmptyViewTypeNoFeed,
    WMFEmptyViewTypeArticleDidNotLoad,
    WMFEmptyViewTypeNoSearchResults,
    WMFEmptyViewTypeNoSavedPages,
    WMFEmptyViewTypeNoHistory
};

@interface UIViewController (WMFEmptyView)

- (void)wmf_showEmptyViewOfType:(WMFEmptyViewType)type;
- (void)wmf_hideEmptyView;
- (BOOL)wmf_isShowingEmptyView;

@end
