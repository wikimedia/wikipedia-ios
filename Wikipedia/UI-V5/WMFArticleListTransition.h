
@import UIKit;

@class WMFArticleListCollectionViewController;
@class WMFArticleContainerViewController;

@interface WMFArticleListTransition : UIPercentDrivenInteractiveTransition <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

- (instancetype)initWithArticleListViewController:(WMFArticleListCollectionViewController*)listViewController articleContainerViewController:(WMFArticleContainerViewController*)articleContainerViewController contentScrollView:(UIScrollView*)scrollView;

@property (nonatomic, weak, readonly) WMFArticleListCollectionViewController* listViewController;
@property (nonatomic, weak, readonly) WMFArticleContainerViewController* articleContainerViewController;
@property (nonatomic, weak, readonly) UIScrollView* scrollView;


/**
 *  Duration of the animation when not interactive
 */
@property (assign, nonatomic) NSTimeInterval nonInteractiveDuration;

/**
 *  Set to NO to disable interactive dismissal
 *  Default is YES
 */
@property (assign, nonatomic) BOOL dismissInteractively;

@end


@protocol WMFArticleListTransitioning <NSObject>

- (UIView*)viewForTransition:(WMFArticleListTransition*)transition;
- (CGRect)frameOfOverlappingListItemsForTransition:(WMFArticleListTransition*)transition;

@end
