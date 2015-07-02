

#import "WMFArticleListTranstion.h"
#import "WMFScrollViewTopPanGestureRecognizer.h"

@interface WMFArticleListTranstion ()<UIGestureRecognizerDelegate>

@property (nonatomic, weak, readwrite) UIViewController* presentingViewController;
@property (nonatomic, weak, readwrite) UIViewController* presentedViewController;
@property (nonatomic, weak, readwrite) UIScrollView* scrollView;

@property (strong, nonatomic) UIView* movingCardSnapshot;
@property (strong, nonatomic) UIView* overlappingCardSnapshot;

@property (nonatomic, assign, readwrite) BOOL isPresented;
@property (nonatomic, assign, readwrite) BOOL isDismissing;
@property (nonatomic, assign, readwrite) BOOL isPresenting;

@property (strong, nonatomic) WMFScrollViewTopPanGestureRecognizer* dismissGestureRecognizer;
@property (assign, nonatomic) BOOL interactionInProgress;

@property (assign, nonatomic) CGFloat totalCardAnimationDistance;

@end

@implementation WMFArticleListTranstion

- (instancetype)initWithPresentingViewController:(UIViewController*)presentingViewController presentedViewController:(UIViewController*)presentedViewController contentScrollView:(UIScrollView*)scrollView {
    self = [super init];
    if (self) {
        _dismissInteractively     = YES;
        _presentingViewController = presentingViewController;
        _presentedViewController  = presentedViewController;
        _scrollView               = scrollView;
        [self addDismissGestureRecognizer];
    }
    return self;
}

- (void)setDismissInteractively:(BOOL)dismissInteractively {
    _dismissInteractively = dismissInteractively;
    [self addDismissGestureRecognizer];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController*)presented presentingController:(UIViewController*)presenting sourceController:(UIViewController*)source {
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController*)dismissed {
    return self;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator {
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    if (self.dismissInteractively) {
        return self;
    }
    return nil;
}

#pragma mark - UIViewAnimatedTransistioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return self.nonInteractiveDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (self.isPresented) {
        [self animateDismiss:transitionContext];
    } else {
        [self animatePresentation:transitionContext];
    }
}

#pragma mark - UIViewControllerInteractiveTransitioning

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    [super startInteractiveTransition:transitionContext];
    self.interactionInProgress = YES;
}

- (CGFloat)completionSpeed {
    return (1 - self.percentComplete) * 1.5;
}

- (UIViewAnimationCurve)completionCurve {
    return UIViewAnimationCurveEaseOut;
}

#pragma mark - Animation

- (void)animatePresentation:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView* containerView = [transitionContext containerView];

    UIViewController* fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController* toVC   = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    UIView* fromView = fromVC.view;
    UIView* toView   = toVC.view;

    //Setup toView
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toVC];
    toView.frame = toViewFinalFrame;
    toView.alpha = 0.0;

    //Setup snapshot of presented card
    UIView* snapshotView = [self.movingCardView snapshotViewAfterScreenUpdates:YES];
    self.movingCardSnapshot = snapshotView;

    //Setup final frame for presented card
    CGRect referenceFrameAdjustedForContainerView = [containerView convertRect:self.movingCardView.frame fromView:self.movingCardView.superview];
    snapshotView.frame = referenceFrameAdjustedForContainerView;
    CGRect finalSnapshotFrame = snapshotView.frame;
    finalSnapshotFrame.origin.y = toViewFinalFrame.origin.y + self.presentCardOffset;

    //How far the animation moves (used to compute percentage for the interactive portion)
    self.totalCardAnimationDistance = referenceFrameAdjustedForContainerView.origin.y - toViewFinalFrame.origin.y;

    //Setup snapshot of overlapping cards
    CGRect referenceFrameAdjustedForFromView = [fromView convertRect:self.movingCardView.frame fromView:self.movingCardView.superview];
    CGRect overlappingCardsSnapshotFrame     = CGRectMake(0, referenceFrameAdjustedForFromView.origin.y + self.offsetOfNextOverlappingCard, CGRectGetWidth(fromView.bounds), CGRectGetHeight(fromView.bounds));
    UIView* overlappingCards                 = [fromView resizableSnapshotViewFromRect:overlappingCardsSnapshotFrame afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
    overlappingCards.frame       = CGRectMake(0, referenceFrameAdjustedForContainerView.origin.y + self.offsetOfNextOverlappingCard, CGRectGetWidth(fromView.bounds), CGRectGetHeight(fromView.bounds));
    self.overlappingCardSnapshot = overlappingCards;

    //Add views to the container
    [containerView addSubview:toView];
    [containerView addSubview:snapshotView];
    [containerView addSubview:overlappingCards];

    self.isPresenting = YES;
    [UIView animateKeyframesWithDuration:self.nonInteractiveDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
            snapshotView.frame = finalSnapshotFrame;
        }];

        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.25 animations:^{
            overlappingCards.frame = CGRectOffset(overlappingCards.frame, 0, -30);
        }];


        [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.75 animations:^{
            overlappingCards.frame = CGRectOffset(overlappingCards.frame, 0, CGRectGetHeight(containerView.frame) - overlappingCards.frame.origin.y);
        }];
    } completion:^(BOOL finished) {
        toView.alpha = 1.0;

        self.isPresenting = NO;
        self.isPresented = ![transitionContext transitionWasCancelled];

        [snapshotView removeFromSuperview];
        [overlappingCards removeFromSuperview];

        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)animateDismiss:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView* containerView = [transitionContext containerView];

    UIViewController* fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];

    UIView* fromView = fromVC.view;
    fromView.alpha = 0.0;

    //Setup snapshot of presented card
    UIView* snapshotView      = self.movingCardSnapshot;
    CGRect finalSnapshotFrame = [containerView convertRect:self.movingCardView.frame fromView:self.movingCardView.superview];

    //Setup snapshot of overlapping cards
    UIView* overlappingCards         = self.overlappingCardSnapshot;
    CGRect finalOverlapSnapshotFrame = CGRectMake(0, finalSnapshotFrame.origin.y + self.offsetOfNextOverlappingCard, CGRectGetWidth(fromView.bounds), CGRectGetHeight(fromView.bounds));

    //Add views to the container
    [containerView addSubview:snapshotView];
    [containerView addSubview:overlappingCards];

    self.isDismissing = YES;
    [UIView animateKeyframesWithDuration:self.nonInteractiveDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
            snapshotView.frame = finalSnapshotFrame;
        }];

        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.75 animations:^{
            overlappingCards.frame = CGRectOffset(finalOverlapSnapshotFrame, 0, -30);
        }];


        [UIView addKeyframeWithRelativeStartTime:0.75 relativeDuration:0.25 animations:^{
            overlappingCards.frame = finalOverlapSnapshotFrame;
        }];
    } completion:^(BOOL finished) {
        if ([transitionContext transitionWasCancelled]) {
            fromView.alpha = 1.0;
        }

        self.isDismissing = NO;
        self.isPresented = [transitionContext transitionWasCancelled];

        [snapshotView removeFromSuperview];
        [overlappingCards removeFromSuperview];

        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

#pragma mark - Gesture

- (void)addDismissGestureRecognizer {
    if (!self.dismissGestureRecognizer) {
        self.dismissGestureRecognizer          = (id)[[WMFScrollViewTopPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissGesture:)];
        self.dismissGestureRecognizer.delegate = self;
        [self.presentedViewController.view addGestureRecognizer:self.dismissGestureRecognizer];
        [self.dismissGestureRecognizer setScrollview:self.scrollView];
    }
}

- (void)removeDismissGestureRecognizer {
    if (self.dismissGestureRecognizer) {
        [self.presentedViewController.view removeGestureRecognizer:self.dismissGestureRecognizer];
        self.dismissGestureRecognizer.delegate = nil;
        self.dismissGestureRecognizer          = nil;
    }
}

- (void)handleDismissGesture:(UIPanGestureRecognizer*)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint translation     = [recognizer translationInView:recognizer.view];
            BOOL swipeIsTopToBottom = translation.y > 0;
            if (swipeIsTopToBottom) {
                [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        }

        case UIGestureRecognizerStateChanged: {
            if (self.interactionInProgress) {
                CGPoint distanceTraveled = [recognizer translationInView:recognizer.view];
                CGFloat percent          = distanceTraveled.y / self.totalCardAnimationDistance;
                if (percent > 0.99) {
                    percent = 0.99;
                }
                [self updateInteractiveTransition:percent];
            }
            break;
        }

        case UIGestureRecognizerStateEnded: {
            if (self.percentComplete >= 0.33) {
                [self finishInteractiveTransition];
                return;
            }

            BOOL fastSwipe = [recognizer velocityInView:recognizer.view].y > self.totalCardAnimationDistance;

            if (fastSwipe) {
                [self finishInteractiveTransition];
                return;
            }

            [self cancelInteractiveTransition];

            break;
        }

        default:
            [self cancelInteractiveTransition];
            break;
    }
}

@end
