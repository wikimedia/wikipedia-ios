@import UIKit;
@class WMFTheme;
@class WMFEmptyView;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WMFEmptyViewType) {
    WMFEmptyViewTypeNone,
    WMFEmptyViewTypeBlank,
    WMFEmptyViewTypeNoFeed,
    WMFEmptyViewTypeArticleDidNotLoad,
    WMFEmptyViewTypeNoSearchResults,
    WMFEmptyViewTypeNoSavedPages,
    WMFEmptyViewTypeNoHistory,
    WMFEmptyViewTypeNoReadingLists,
    WMFEmptyViewTypeNoSavedPagesInReadingList
};

@protocol WMFEmptyViewContainer

- (void)addEmptyView:(UIView *)emptyView;

@end

@interface UIViewController (WMFEmptyView)

- (void)wmf_showEmptyViewOfType:(WMFEmptyViewType)type theme:(WMFTheme *)theme frame:(CGRect)frame;
- (void)wmf_setEmptyViewFrame:(CGRect)frame;
- (void)wmf_hideEmptyView;
- (BOOL)wmf_isShowingEmptyView;
- (void)wmf_applyThemeToEmptyView:(WMFTheme *)theme;
@property (nonatomic, readonly, nullable) WMFEmptyView *wmf_emptyView;

@end

NS_ASSUME_NONNULL_END
