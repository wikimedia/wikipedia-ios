
@import UIKit;

@class WMFArticleListCollectionViewController;
@class WMFArticleContainerViewController;

@interface WMFArticleListTransition : UIPercentDrivenInteractiveTransition
    <UIViewControllerAnimatedTransitioning>

@property (nonatomic, weak, readonly) WMFArticleListCollectionViewController* listViewController;
@property (nonatomic, weak) WMFArticleContainerViewController* articleContainerViewController;

- (instancetype)initWithListCollectionViewController:(WMFArticleListCollectionViewController*)listViewController
    NS_DESIGNATED_INITIALIZER;

/**
 *  Duration of the animation when not interactive
 */
@property (assign, nonatomic) NSTimeInterval nonInteractiveDuration;

/**
 *  Whether or not the receiver is setup to start a dismissal transition.
 */
@property (nonatomic, assign, readonly) BOOL isDismissing;

/**
 *  Whether or not the receiver is setup to start a presentation transition.
 *
 *  Inverse of `isDismissing`.
 */
@property (nonatomic, assign, readonly) BOOL isPresenting;

@end

@protocol WMFArticleListTransitioning <NSObject>

- (UIView*)viewForTransition:(WMFArticleListTransition*)transition;
- (CGRect)frameOfOverlappingListItemsForTransition:(WMFArticleListTransition*)transition;

@end
