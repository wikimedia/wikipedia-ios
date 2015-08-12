#import "WMFArticleListTransition.h"
#import "WMFScrollViewTopPanGestureRecognizer.h"
#import "WMFArticleListCollectionViewController_Transitioning.h"
#import "WMFArticleContainerViewController.h"
#import "WMFArticleViewController.h"
#import "UIView+WMFShapshotting.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "WMFMath.h"

@interface WMFArticleListTransition ()<UIGestureRecognizerDelegate>

@property (nonatomic, assign, readwrite) BOOL isDismissing;
@property (nonatomic, assign, readwrite) BOOL isPresenting;

@property (nonatomic, weak, readwrite) WMFArticleListCollectionViewController* listViewController;
@property (nonatomic, weak) UIScrollView* scrollView;
@property (strong, nonatomic) WMFScrollViewTopPanGestureRecognizer* dismissGestureRecognizer;
@property (assign, nonatomic) BOOL didStartInteractiveDismissal;

@property (assign, nonatomic) CGFloat totalCardAnimationDistance;

@end

@implementation WMFArticleListTransition

- (instancetype)initWithListCollectionViewController:(WMFArticleListCollectionViewController*)listViewController {
    self = [super init];
    if (self) {
        self.listViewController = listViewController;
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
    DDLogVerbose(@"Interactive transition did start.");
    self.didStartInteractiveDismissal = YES;
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
    /*
       !!!: Snapshot must be taken before screen updates otherwise the snapshot will be cut short
     */
    UIView* snapshotView = [selectedCardView wmf_addSnapshotToView:containerView afterScreenUpdates:NO];

    CGRect snapShotFinalFrame = toViewFinalFrame;
    snapShotFinalFrame.size = snapshotView.frame.size;

    // Setup overlaping screen shot
    CGRect overlapRect      = [self.listViewController frameOfOverlappingListItemsForTransition:self];
    UIView* overlapSnapshot = [self.listViewController.view wmf_addResizableSnapshotToView:containerView
                                                                                  fromRect:overlapRect
                                                                        afterScreenUpdates:NO
                                                                             withCapInsets:UIEdgeInsetsZero];

    // How far the animation moves (used to compute percentage for the interactive portion)
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
    UIViewController* toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView* fromView      = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView* toView        = [transitionContext viewForKey:UITransitionContextToViewKey];

    // Setup snapshot of presented card
    [self.articleContainerViewController.articleViewController.tableView wmf_scrollToTop:NO];
    /*
       !!!: Snapshot must be taken before screen updates, otherwise the list view will flicker before the fullscreen card
          is presented on top of it
     */
    UIView* fullscreenArticleSnapshotView =
        [self.articleContainerViewController.articleViewController.view wmf_addSnapshotToView:containerView
                                                                           afterScreenUpdates:NO];

    // setup list behind fullscreen article
    // !!!: adding list view behind presented card snapshot prevents the list flickering when transition starts
    [containerView insertSubview:toView belowSubview:fullscreenArticleSnapshotView];
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toVC];
    toView.frame = toViewFinalFrame;
    // Scroll the list to make the card we're dismissing visible (e.g. in case its index changed)
    [self.listViewController scrollToArticleIfOffscreen:self.articleContainerViewController.article animated:NO];

    // Setup snapshot of cards overlapping the fullscreen article (when in the list)
    // !!!: adding overlapping cards to the container after setting frames prevents flickering when transition starts
    CGRect overlapRect = [self.listViewController frameOfOverlappingListItemsForTransition:self];

    /*
       !!!: Snapshot must be taken after screen updates, otherwise the overlapping card titles will not be rendered
     */
    UIView* overlapSnapshot = [self.listViewController.view wmf_addResizableSnapshotToView:containerView
                                                                                  fromRect:overlapRect
                                                                        afterScreenUpdates:YES
                                                                             withCapInsets:UIEdgeInsetsZero];
    // start overlapping card snapshot offscreen
    overlapSnapshot.frame = CGRectOffset(overlapSnapshot.frame,
                                         0,
                                         containerView.frame.size.height - overlapSnapshot.frame.origin.y);

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
            overlapSnapshot.frame = CGRectOffset(overlapRect, 0, -30);
        }];


        [UIView addKeyframeWithRelativeStartTime:0.75 relativeDuration:0.25 animations:^{
            overlapSnapshot.frame = overlapRect;
        }];
    }
                              completion:^(BOOL finished) {
        if ([transitionContext transitionWasCancelled]) {
            fromView.alpha = 1.0;
        }

        toView.alpha = 1.0;
        [fullscreenArticleSnapshotView removeFromSuperview];
        [overlapSnapshot removeFromSuperview];

        self.didStartInteractiveDismissal = NO;
        self.isDismissing = [transitionContext transitionWasCancelled];

        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
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
    self.dismissGestureRecognizer.scrollView = self.scrollView;
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
            if (recognizer.isRecordingVerticalDisplacement) {
                CGFloat transitionProgress =
                    WMFStrictClamp(0.0, recognizer.aboveBoundsVerticalDisplacement / self.totalCardAnimationDistance, 1.0);
                if (!self.didStartInteractiveDismissal) {
                    DDLogVerbose(@"Starting dismissal.");
                    [self.articleContainerViewController.navigationController popViewControllerAnimated:YES];
                } else {
                    DDLogVerbose(@"Interactive transition progress: %f / %f = %f",
                                 recognizer.aboveBoundsVerticalDisplacement,
                                 self.totalCardAnimationDistance,
                                 transitionProgress);
                    [self updateInteractiveTransition:transitionProgress];
                }
            }
            break;
        }

        case UIGestureRecognizerStateEnded: {
            CGFloat verticalVelocity =
                [self.dismissGestureRecognizer velocityInView:self.dismissGestureRecognizer.view].y;
            if (self.didStartInteractiveDismissal) {
                if (self.percentComplete >= 0.33) {
                    DDLogInfo(@"Finishing transition since user released touch above percentComplete threshold.");
                    [self finishInteractiveTransition];
                } else if (verticalVelocity >= self.totalCardAnimationDistance) {
                    DDLogInfo(@"Finishing transition since user swiped above velocity threshold.");
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
            if (self.didStartInteractiveDismissal) {
                DDLogVerbose(@"Canceling interactive transition.");
                [self cancelInteractiveTransition];
            }
            break;
        }

        default:
            break;
    }
}

@end
