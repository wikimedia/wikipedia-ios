
@import UIKit;

@interface WMFArticleListTranstion : UIPercentDrivenInteractiveTransition <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

- (instancetype)initWithPresentingViewController:(UIViewController*)presentingViewController presentedViewController:(UIViewController*)presentedViewController contentScrollView:(UIScrollView*)scrollView;

@property (nonatomic, weak, readonly) UIViewController* presentingViewController;
@property (nonatomic, weak, readonly) UIViewController* presentedViewController;
@property (nonatomic, weak, readonly) UIScrollView* scrollView;

/**
 *  Duration of the animation when not interactive
 */
@property (assign, nonatomic) NSTimeInterval nonInteractiveDuration;

/**
 *  Y Distance to the next card that overlaps the animating card.
 *  The transisition uses this information for snapshoting purposes.
 */
@property (assign, nonatomic) CGFloat offsetOfNextOverlappingCard;

/**
 *  The view to be transistioned into the presented view.
 *  This view will be snapshotted.
 */
@property (strong, nonatomic) UIView* movingCardView;

/**
 *  The y offset of the final postiion of the presented card in the presented view frame.
 *  This is used to calculate the final frame of the moving card view.
 *
 *  This is useful for conveying things like content inset in the presented view controller.
 *  This is used instead of frame because the full frame is difficult to know before presentation begins.
 */
@property (assign, nonatomic) CGFloat presentCardOffset;


/**
 *  Set to NO to disable interactive dismissal
 *  Default is YES
 */
@property (assign, nonatomic) BOOL dismissInteractively;

@end
