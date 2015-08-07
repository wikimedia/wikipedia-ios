#import "WMFArticleListTransition.h"
#import "WMFScrollViewTopPanGestureRecognizer.h"
#import "WMFArticleListCollectionViewController.h"
#import "WMFArticleContainerViewController.h"
#import "WMFArticleViewController.h"
#import "UIView+WMFShapshotting.h"
#import "WMFMath.h"

typedef NS_ENUM (NSInteger, WMFArticleListTransitionDismissalState) {
    WMFArticleListTransitionDismissalStateInactive,
    WMFArticleListTransitionDismissalStatePending,
    WMFArticleListTransitionDismissalStateActive
};

@interface WMFArticleListTransition ()<UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIScrollView* scrollView;
@property (strong, nonatomic) WMFScrollViewTopPanGestureRecognizer* dismissGestureRecognizer;
@property (assign, nonatomic) WMFArticleListTransitionDismissalState dismissalState;

@property (assign, nonatomic) CGFloat totalCardAnimationDistance;

@end

@implementation WMFArticleListTransition

- (instancetype)init {
    self = [super init];
    if (self) {
        _nonInteractiveDuration = 0.5;
        _isDismissing           = NO;
    }
    return self;
}

- (BOOL)isPresenting {
    return !self.isDismissing;
}

- (void)setIsPresenting:(BOOL)isPresenting {
    self.isDismissing = !isPresenting;
}

#pragma mark - UIViewAnimatedTransistioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return self.nonInteractiveDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (self.isDismissing) {
        [self animateDismiss:transitionContext];
    } else {
        [self animatePresentation:transitionContext];
    }
}

#pragma mark - UIViewControllerInteractiveTransitioning

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    [super startInteractiveTransition:transitionContext];
    NSAssert(self.isDismissing, @"This class only supports interactive dismissal, not presentation.");
}

- (CGFloat)completionSpeed {
    return (1 - self.percentComplete) * 1.5;
}

- (UIViewAnimationCurve)completionCurve {
    return UIViewAnimationCurveEaseOut;
}

#pragma mark - Animation

- (void)animatePresentation:(id<UIViewControllerContextTransitioning>)transitionContext {
    DDLogVerbose(@"Animating presentation from %@ to %@", self.listViewController, self.articleContainerViewController);
    UIView* containerView  = [transitionContext containerView];
    UIView* toView         = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIViewController* toVC = self.articleContainerViewController;

    //Setup toView
    [containerView addSubview:toView];
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toVC];
    toView.frame = toViewFinalFrame;
    toView.alpha = 0.0;

    //Setup snapshot of presented card
    UIView* selectedCardView = [self.listViewController viewForTransition:self];
    NSParameterAssert(selectedCardView);
    UIView* snapshotView = [selectedCardView wmf_addSnapshotToView:containerView afterScreenUpdates:NO];

    CGRect snapShotFinalFrame = toViewFinalFrame;
    snapShotFinalFrame.size = snapshotView.frame.size;

    //Setup overlaping screen shot
    CGRect overlapRect      = [self.listViewController frameOfOverlappingListItemsForTransition:self];
    UIView* overlapSnapshot = [self.listViewController.view wmf_addResizableSnapshotToView:containerView
                                                                                  fromRect:overlapRect
                                                                        afterScreenUpdates:NO
                                                                             withCapInsets:UIEdgeInsetsZero];

    //How far the animation moves (used to compute percentage for the interactive portion)
    self.totalCardAnimationDistance = snapshotView.frame.origin.y - toViewFinalFrame.origin.y;

    [UIView animateKeyframesWithDuration:self.nonInteractiveDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
            snapshotView.frame = snapShotFinalFrame;
        }];

        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.25 animations:^{
            overlapSnapshot.frame = CGRectOffset(overlapSnapshot.frame, 0, -30);
        }];


        [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.75 animations:^{
            overlapSnapshot.frame = CGRectOffset(overlapSnapshot.frame,
                                                 0,
                                                 containerView.frame.size.height - overlapSnapshot.frame.origin.y);
        }];
    } completion:^(BOOL finished) {
        toView.alpha = 1.0;

        [snapshotView removeFromSuperview];
        [overlapSnapshot removeFromSuperview];

        self.isPresenting = [transitionContext transitionWasCancelled];

        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)animateDismiss:(id<UIViewControllerContextTransitioning>)transitionContext {
    DDLogVerbose(@"Animating dismissal from %@ to %@", self.articleContainerViewController, self.listViewController);
    UIView* containerView = [transitionContext containerView];
    UIView* fromView      = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView* toView        = [transitionContext viewForKey:UITransitionContextToViewKey];

    // Setup snapshot of presented card
    // !!!: need to reset scrollview offset otherwise a white bar will appear atop the snapshot
    self.articleContainerViewController.articleViewController.tableView.contentOffset =
        CGPointMake(self.articleContainerViewController.articleViewController.tableView.contentInset.left,
                    self.articleContainerViewController.articleViewController.tableView.contentInset.top);
    UIView* fullscreenArticleSnapshotView =
        [self.articleContainerViewController.articleViewController.view wmf_addSnapshotToView:containerView
                                                                           afterScreenUpdates:YES];

    // setup list behind fullscreen article
    [containerView insertSubview:toView belowSubview:fullscreenArticleSnapshotView];
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:self.listViewController];
    toView.frame = toViewFinalFrame;
    //Scroll the list if needed (the list may have changed)
    [self.listViewController scrollToArticleIfOffscreen:self.articleContainerViewController.article animated:NO];


    // Setup snapshot of cards overlapping the fullscreen article (when in the list)
    CGRect overlapRect      = [self.listViewController frameOfOverlappingListItemsForTransition:self];
    UIView* overlapSnapshot = [self.listViewController.view wmf_addResizableSnapshotToView:containerView
                                                                                  fromRect:overlapRect
                                                                        afterScreenUpdates:YES
                                                                             withCapInsets:UIEdgeInsetsZero];

    // keep reference to original position of overlapping cards
    CGRect overlappingCardsListPosition = overlapSnapshot.frame;

    // start overlapping card snapshot offscreen
    overlapSnapshot.frame = CGRectOffset(overlapSnapshot.frame,
                                         0,
                                         CGRectGetHeight(containerView.frame) - CGRectGetMinY(overlapSnapshot.frame));

    // get final rect of fullscreen card
    UIView* selectedCardViewFromList = [self.listViewController viewForTransition:self];
    CGPoint fullscreenCardFinalPosition;
    if (selectedCardViewFromList) {
        // item still exists in list, set the snapshot's final frame to its position in the list
        fullscreenCardFinalPosition = [containerView convertPoint:selectedCardViewFromList.frame.origin
                                                         fromView:selectedCardViewFromList.superview];
    } else {
        // item was removed, animate offscreen
        fullscreenCardFinalPosition = CGPointMake(0, CGRectGetMaxY(containerView.frame));
    }
    CGRect fullscreenCardFinalFrame = (CGRect){
        .origin = fullscreenCardFinalPosition,
        .size   = fullscreenArticleSnapshotView.frame.size
    };

    self.totalCardAnimationDistance = fullscreenCardFinalFrame.origin.y - fullscreenArticleSnapshotView.frame.origin.y;

    [UIView animateKeyframesWithDuration:self.nonInteractiveDuration
                                   delay:0.0
                                 options:UIViewKeyframeAnimationOptionCalculationModeCubic
                              animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
            fullscreenArticleSnapshotView.frame = fullscreenCardFinalFrame;
        }];

        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.75 animations:^{
            overlapSnapshot.frame = CGRectOffset(overlappingCardsListPosition, 0, -30);
        }];


        [UIView addKeyframeWithRelativeStartTime:0.75 relativeDuration:0.25 animations:^{
            overlapSnapshot.frame = overlappingCardsListPosition;
        }];
    }
                              completion:^(BOOL finished) {
        if ([transitionContext transitionWasCancelled]) {
            fromView.alpha = 1.0;
        }

        toView.alpha = 1.0;
        [fullscreenArticleSnapshotView removeFromSuperview];
        [overlapSnapshot removeFromSuperview];

        self.dismissalState = WMFArticleListTransitionDismissalStateInactive;
        self.isDismissing = [transitionContext transitionWasCancelled];

        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];

    self.dismissalState = WMFArticleListTransitionDismissalStateActive;
}

#pragma mark - Gesture

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    return YES;
}

- (UIGestureRecognizer*)dismissGestureRecognizer {
    if (!_dismissGestureRecognizer) {
        _dismissGestureRecognizer =
            [[WMFScrollViewTopPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissGesture:)];
        _dismissGestureRecognizer.delegate             = self;
        _dismissGestureRecognizer.delaysTouchesBegan   = NO;
        _dismissGestureRecognizer.cancelsTouchesInView = NO;
    }
    return _dismissGestureRecognizer;
}

- (void)setArticleContainerViewController:(WMFArticleContainerViewController*)articleContainerViewController {
    if (_articleContainerViewController == articleContainerViewController) {
        return;
    }
    _articleContainerViewController = articleContainerViewController;
    _scrollView                     = _articleContainerViewController.articleViewController.tableView;
    [self.articleContainerViewController.view addGestureRecognizer:self.dismissGestureRecognizer];
    self.dismissGestureRecognizer.scrollview = self.scrollView;
}

- (void)removeDismissGestureRecognizer {
    if (self.dismissGestureRecognizer) {
        [self.articleContainerViewController.view removeGestureRecognizer:self.dismissGestureRecognizer];
        self.dismissGestureRecognizer.delegate = nil;
        self.dismissGestureRecognizer          = nil;
    }
}

- (void)handleDismissGesture:(WMFScrollViewTopPanGestureRecognizer*)recognizer {
    NSAssert(self.isDismissing, @"isDimissing flag was not set after presentation!");
    switch (recognizer.state) {
        case UIGestureRecognizerStateChanged: {
            if (recognizer.didStart) {
                CGFloat transitionProgress =
                    WMFStrictClamp(0.0, recognizer.postBoundsTranslation / self.totalCardAnimationDistance, 1.0);
                if (self.dismissalState == WMFArticleListTransitionDismissalStateInactive) {
                    DDLogVerbose(@"Starting dismissal.");
                    /*
                       !!!: Must set this flag here since the gesture recognizer callbacks will fire again, causing this
                          method to be entered before startInteractiveTransition is called, causing us to call pop
                          more than once.
                     */
                    self.dismissalState = WMFArticleListTransitionDismissalStatePending;
                    [self.articleContainerViewController.navigationController popViewControllerAnimated:YES];
                } else {
                    DDLogVerbose(@"Interactive transition progress: %f / %f = %f",
                                 recognizer.postBoundsTranslation, self.totalCardAnimationDistance, transitionProgress);
                    [self updateInteractiveTransition:transitionProgress];
                }
            }
            break;
        }

        case UIGestureRecognizerStateEnded: {
            if (self.dismissalState == WMFArticleListTransitionDismissalStateActive) {
                if (self.percentComplete >= 0.33) {
                    DDLogVerbose(@"Finishing interactive transition.");
                    [self finishInteractiveTransition];
                } else {
                    DDLogVerbose(@"Canceling interactive transition.");
                    [self cancelInteractiveTransition];
                }
            } else {
                DDLogVerbose(@"Touch ended w/o transition starting.");
            }
            break;
        }

        case UIGestureRecognizerStateCancelled: {
            DDLogVerbose(@"Canceling interactive transition.");
            [self cancelInteractiveTransition];
            break;
        }

        default:
            break;
    }
}

@end
