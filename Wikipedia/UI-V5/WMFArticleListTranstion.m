

#import "WMFArticleListTranstion.h"
#import "WMFScrollViewTopPanGestureRecognizer.h"
#import "WMFArticleListCollectionViewController.h"
#import "WMFArticleContainerViewController.h"
#import "UIView+WMFShapshotting.h"

@interface WMFArticleListTranstion ()<UIGestureRecognizerDelegate>

@property (nonatomic, weak, readwrite) WMFArticleListCollectionViewController* listViewController;
@property (nonatomic, weak, readwrite) WMFArticleContainerViewController* articleContainerViewController;
@property (nonatomic, weak, readwrite) UIScrollView* scrollView;

@property (nonatomic, assign, readwrite) BOOL isPresented;
@property (nonatomic, assign, readwrite) BOOL isDismissing;
@property (nonatomic, assign, readwrite) BOOL isPresenting;

@property (strong, nonatomic) WMFScrollViewTopPanGestureRecognizer* dismissGestureRecognizer;
@property (assign, nonatomic) BOOL interactionInProgress;

@property (assign, nonatomic) CGFloat totalCardAnimationDistance;

@end

@implementation WMFArticleListTranstion

- (instancetype)initWithArticleListViewController:(WMFArticleListCollectionViewController*)listViewController articleContainerViewController:(WMFArticleContainerViewController*)articleContainerViewController contentScrollView:(UIScrollView*)scrollView {
    self = [super init];
    if (self) {
        _nonInteractiveDuration         = 0.5;
        _dismissInteractively           = YES;
        _listViewController             = listViewController;
        _articleContainerViewController = articleContainerViewController;
        _scrollView                     = scrollView;
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

    UIViewController* toVC = self.articleContainerViewController;

    UIView* toView = toVC.view;
    [containerView addSubview:toView];

    //Setup toView
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toVC];
    toView.frame = toViewFinalFrame;
    toView.alpha = 0.0;

    //Setup snapshot of presented card
    UIView* transitioningView = [self.listViewController viewForTransition:self];
    UIView* snapshotView      = [transitioningView wmf_snapshotAfterScreenUpdates:YES andAddToContainerView:containerView];
    CGRect snapShotFinalFrame = toViewFinalFrame;
    snapShotFinalFrame.size = snapshotView.frame.size;

    //Setup overlaping screen shot
    CGRect overlapRect      = [self.listViewController frameOfOverlappingListItemsForTransition:self];
    UIView* overlapSnapshot = [self.listViewController.view wmf_resizableSnapshotViewFromRect:overlapRect afterScreenUpdates:YES andAddToContainerView:containerView];

    //How far the animation moves (used to compute percentage for the interactive portion)
    self.totalCardAnimationDistance = snapshotView.frame.origin.y - toViewFinalFrame.origin.y;

    self.isPresenting = YES;
    [UIView animateKeyframesWithDuration:self.nonInteractiveDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
            snapshotView.frame = snapShotFinalFrame;
        }];

        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.25 animations:^{
            overlapSnapshot.frame = CGRectOffset(overlapSnapshot.frame, 0, -30);
        }];


        [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.75 animations:^{
            overlapSnapshot.frame = CGRectOffset(overlapSnapshot.frame, 0, CGRectGetHeight(containerView.frame) - CGRectGetMinY(overlapSnapshot.frame));
        }];
    } completion:^(BOOL finished) {
        toView.alpha = 1.0;

        self.isPresenting = NO;
        self.isPresented = ![transitionContext transitionWasCancelled];

        [snapshotView removeFromSuperview];
        [overlapSnapshot removeFromSuperview];

        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)animateDismiss:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView* containerView = [transitionContext containerView];

    UIViewController* fromVC = self.articleContainerViewController;
    UIViewController* toVC   = self.listViewController;

    UIView* fromView = fromVC.view;

    fromView.alpha = 0.0;

    //Scroll the list if needed (the list may have changed)
    [self.listViewController scrollToArticleIfOffscreen:self.articleContainerViewController.article animated:NO];

    //Setup snapshot of presented card
    UIView* transitioningView = self.articleContainerViewController.view;
    UIView* snapshotView      = [transitioningView wmf_snapshotAfterScreenUpdates:NO andAddToContainerView:containerView];
    UIView* articleInList     = [self.listViewController viewForTransition:self];
    CGRect finalSnapshotFrame;
    if (articleInList) {
        finalSnapshotFrame = [containerView convertRect:articleInList.frame fromView:articleInList.superview];
    } else {
        finalSnapshotFrame = CGRectOffset(snapshotView.frame, 0.0, CGRectGetHeight(snapshotView.frame));
    }
    finalSnapshotFrame.size = snapshotView.frame.size;

    //Setup overlaping screen shot
    CGRect overlapRect               = [self.listViewController frameOfOverlappingListItemsForTransition:self];
    UIView* overlapSnapshot          = [self.listViewController.view wmf_resizableSnapshotViewFromRect:overlapRect afterScreenUpdates:YES andAddToContainerView:containerView];
    CGRect finalOverlapSnapshotFrame = overlapSnapshot.frame;
    overlapSnapshot.frame = CGRectOffset(overlapSnapshot.frame, 0, CGRectGetHeight(containerView.frame) - CGRectGetMinY(overlapSnapshot.frame));

    //How far the animation moves (used to compute percentage for the interactive portion)
    self.totalCardAnimationDistance = finalSnapshotFrame.origin.y - snapshotView.frame.origin.y;

    self.isDismissing = YES;
    [UIView animateKeyframesWithDuration:self.nonInteractiveDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
            snapshotView.frame = finalSnapshotFrame;
        }];

        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.75 animations:^{
            overlapSnapshot.frame = CGRectOffset(finalOverlapSnapshotFrame, 0, -30);
        }];


        [UIView addKeyframeWithRelativeStartTime:0.75 relativeDuration:0.25 animations:^{
            overlapSnapshot.frame = finalOverlapSnapshotFrame;
        }];
    } completion:^(BOOL finished) {
        if ([transitionContext transitionWasCancelled]) {
            fromView.alpha = 1.0;
        }

        self.isDismissing = NO;
        self.isPresented = [transitionContext transitionWasCancelled];

        [snapshotView removeFromSuperview];
        [overlapSnapshot removeFromSuperview];

        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

#pragma mark - Gesture

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    return YES;
}

- (void)addDismissGestureRecognizer {
    if (!self.dismissGestureRecognizer) {
        self.dismissGestureRecognizer          = (id)[[WMFScrollViewTopPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissGesture:)];
        self.dismissGestureRecognizer.delegate = self;
        [self.articleContainerViewController.view addGestureRecognizer:self.dismissGestureRecognizer];
        [self.dismissGestureRecognizer setScrollview:self.scrollView];
    }
}

- (void)removeDismissGestureRecognizer {
    if (self.dismissGestureRecognizer) {
        [self.articleContainerViewController.view removeGestureRecognizer:self.dismissGestureRecognizer];
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
                [self.articleContainerViewController dismissViewControllerAnimated:YES completion:nil];
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
