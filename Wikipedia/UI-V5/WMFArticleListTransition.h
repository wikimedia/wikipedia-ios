
@import UIKit;

@class WMFArticleListCollectionViewController;
@class WMFArticleContainerViewController;

@interface WMFArticleListTransition : UIPercentDrivenInteractiveTransition
<UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL isDismissing;
@property (nonatomic, assign) BOOL isPresenting;

@property (nonatomic, weak) WMFArticleListCollectionViewController* listViewController;
@property (nonatomic, weak) WMFArticleContainerViewController* articleContainerViewController;

/**
 *  Duration of the animation when not interactive
 */
@property (assign, nonatomic) NSTimeInterval nonInteractiveDuration;

@end

@protocol WMFArticleListTranstioning <NSObject>

- (UIView*)viewForTransition:(WMFArticleListTransition*)transition;
- (CGRect)frameOfOverlappingListItemsForTransition:(WMFArticleListTransition*)transition;

@end
