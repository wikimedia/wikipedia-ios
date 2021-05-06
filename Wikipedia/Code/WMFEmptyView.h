@import UIKit;
@import WMF.Swift;

@protocol WMFEmptyViewDelegate
@optional
- (void)heightChanged:(CGFloat)height;
@end

@interface WMFEmptyView : UIView <WMFThemeable>

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, strong, readonly) NSString *backgroundColorKeyPath;

@property (nonatomic, weak) id<WMFEmptyViewDelegate> delegate;

+ (instancetype)blankEmptyView;
+ (instancetype)noFeedEmptyView;
+ (instancetype)noArticleEmptyView;
+ (instancetype)noSearchResultsEmptyView;
+ (instancetype)noSavedPagesEmptyView;
+ (instancetype)noSavedPagesInReadingListEmptyView;
+ (instancetype)noReadingListsEmptyViewWithTarget:(nullable id)target action:(nullable SEL)action;
+ (instancetype)noHistoryEmptyView;
+ (instancetype)noInternetConnectionEmptyView;
+ (instancetype)noSelectedImageToInsertEmptyView;
+ (instancetype)unableToLoadTalkPageEmptyView;
+ (instancetype)emptyTalkPageEmptyView;
+ (instancetype)emptyDiffCompareEmptyView;
+ (instancetype)emptyDiffSingleEmptyView;
+ (instancetype)errorDiffCompareEmptyView;
+ (instancetype)errorDiffSingleEmptyView;
+ (instancetype)noOtherArticleLanguagesEmptyView;

NS_ASSUME_NONNULL_END

@end
