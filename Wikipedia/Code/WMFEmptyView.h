@import UIKit;
@import WMF.Swift;

@interface WMFEmptyView : UIView <WMFThemeable>

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, strong, readonly) NSString *backgroundColorKeyPath;

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
+ (instancetype)emptyDiffEmptyView;

NS_ASSUME_NONNULL_END

@end
