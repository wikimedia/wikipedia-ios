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
+ (instancetype)noInternetConnectionEmptyView;
+ (instancetype)noSelectedImageToInsertEmptyView;
+ (instancetype)unableToLoadTalkPageEmptyView;
+ (instancetype)emptyTalkPageEmptyView;
- (void)offsetContentCenterYWithConstant:(CGFloat)constant;

NS_ASSUME_NONNULL_END

@end
