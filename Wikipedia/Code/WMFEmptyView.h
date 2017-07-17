@import UIKit;
@import WMF.Swift;

@interface WMFEmptyView : UIView <WMFThemeable>

+ (instancetype)blankEmptyView;
+ (instancetype)noFeedEmptyView;
+ (instancetype)noArticleEmptyView;
+ (instancetype)noSearchResultsEmptyView;
+ (instancetype)noSavedPagesEmptyView;
+ (instancetype)noHistoryEmptyView;

@end
