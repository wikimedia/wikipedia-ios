@import UIKit;
@import WMF.Swift;

@interface WMFEmptyView : UIView <WMFThemeable>

NS_ASSUME_NONNULL_BEGIN

+ (instancetype)blankEmptyView;
+ (instancetype)noFeedEmptyView;
+ (instancetype)noArticleEmptyView;
+ (instancetype)noSearchResultsEmptyView;
+ (instancetype)noSavedPagesEmptyView;
+ (instancetype)noSavedPagesInReadingListEmptyView;
+ (instancetype)noReadingListsEmptyViewWithTarget:(nullable id)target action:(nonnull SEL)action;
+ (instancetype)noHistoryEmptyView;

NS_ASSUME_NONNULL_END

@end
