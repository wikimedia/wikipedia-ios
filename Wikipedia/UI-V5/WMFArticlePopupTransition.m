

#import "WMFArticlePopupTransition.h"
#import "WMFScrollViewTopPanGestureRecognizer.h"
#import <BlocksKit/BlocksKit+UIKit.h>

@interface WMFArticlePopupTransition ()<UIGestureRecognizerDelegate>

@property (nonatomic, weak, readwrite) UIViewController* presentingViewController;
@property (nonatomic, weak, readwrite) UIViewController* presentedViewController;
@property (nonatomic, weak, readwrite) UIScrollView* scrollView;

@property (nonatomic, assign, readwrite) BOOL isPresented;
@property (nonatomic, assign, readwrite) BOOL isDismissing;
@property (nonatomic, assign, readwrite) BOOL isPresenting;

@property (strong, nonatomic) UIPanGestureRecognizer* presentGestureRecognizer;
@property (strong, nonatomic) WMFScrollViewTopPanGestureRecognizer* dismissGestureRecognizer;
@property (assign, nonatomic) BOOL interactionInProgress;

@property (assign, nonatomic) CGFloat popupAnimationSpeed;
@property (strong, nonatomic) CADisplayLink* popupAnimationTimer;
@property (assign, nonatomic) CGFloat popupAnimationStartTime;
@property (assign, nonatomic) CGFloat popupHeightAsProgress;
@property (assign, nonatomic) CGFloat totalCardAnimationDistance;

@end


@implementation WMFArticlePopupTransition

- (instancetype)initWithPresentingViewController:(UIViewController*)presentingViewController presentedViewController:(UIViewController*)presentedViewController contentScrollView:(UIScrollView*)scrollView {
    self = [super init];
    if (self) {
        _presentInteractively     = YES;
        _dismissInteractively     = YES;
        _popupHeight              = 300.0;
        _popupAnimationSpeed      = 100 / 0.3;
        _presentingViewController = presentingViewController;
        _presentedViewController  = presentedViewController;
        _scrollView               = scrollView;
        [self addPresentGestureRecoginizer];
    }
    return self;
}

- (void)setPresentInteractively:(BOOL)presentInteractively {
    _presentInteractively = presentInteractively;
    [self addPresentGestureRecoginizer];
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
    if (self.presentInteractively) {
        return self;
    }
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
    self.totalCardAnimationDistance = CGRectGetHeight([transitionContext containerView].frame);

    if (self.isPresented) {
        [self animateDismiss:transitionContext];
    } else {
        [self animatePresentation:transitionContext];
    }
}

#pragma mark - UIViewControllerInteractiveTransitioning

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    //this needs to happen before super becuase it is used to modify the animations that start in the super call
    self.interactionInProgress = YES;
    [super startInteractiveTransition:transitionContext];

    if (!self.isPresented) {
        //Animate the transition partially to get the view on screen
        [self animateToPopupPosition];
    }
}

- (CGFloat)completionSpeed {
    return (1 - self.percentComplete) * 1.5;
}

- (UIViewAnimationCurve)completionCurve {
    return UIViewAnimationCurveEaseOut;
}

#pragma mark - Animation

- (CGFloat)animationProgressFromHeight:(CGFloat)height {
    return height / self.totalCardAnimationDistance;
}

- (void)animateToPopupPosition {
    self.popupHeightAsProgress   = [self animationProgressFromHeight:self.popupHeight];
    self.popupAnimationStartTime = CACurrentMediaTime();
    self.popupAnimationTimer     = [CADisplayLink displayLinkWithTarget:self selector:@selector(animatePopupWithTimer:)];
    [self.popupAnimationTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)animatePopupWithTimer:(CADisplayLink*)link {
    NSTimeInterval elapedTime   = link.timestamp - self.popupAnimationStartTime;
    CGFloat distance            = elapedTime * self.popupAnimationSpeed;
    CGFloat progressDifferental = [self animationProgressFromHeight:distance];

    CGFloat percentComplete = [self percentComplete];

    if (percentComplete < self.popupHeightAsProgress) {
        percentComplete = [self percentComplete] + progressDifferental;

        if (percentComplete >= self.popupHeightAsProgress) {
            percentComplete = self.popupHeightAsProgress;
            [link invalidate];
            link = nil;
        }
    } else {
        percentComplete = [self percentComplete] - progressDifferental;

        if (percentComplete <= self.popupHeightAsProgress) {
            percentComplete = self.popupHeightAsProgress;
            [link invalidate];
            link = nil;
        }
    }

    [self updateInteractiveTransition:percentComplete];
}

- (void)animatePresentation:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView* containerView = [transitionContext containerView];

//    UIViewController* fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController* toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

//    UIView* fromView = fromVC.view;
    UIView* toView = toVC.view;

    //Setup toView
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toVC];

    CGRect toViewStartFrame;

    if ([toView superview]) {
        toViewStartFrame = [containerView convertRect:toView.frame fromView:[toView superview]];
    } else {
        toViewStartFrame          = toViewFinalFrame;
        toViewStartFrame.origin.y = CGRectGetHeight(containerView.bounds);
    }

    toView.frame = toViewStartFrame;
    [containerView addSubview:toView];

    self.isPresenting = YES;

    [self performAnimations:^{
        toView.frame = toViewFinalFrame;
    } completion:^(BOOL finished) {
        self.isPresenting = NO;
        self.isPresented = ![transitionContext transitionWasCancelled];

        [self addDismissGestureRecognizer];
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)animateDismiss:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView* containerView = [transitionContext containerView];

    UIViewController* fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
//    UIViewController* toVC   = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    UIView* fromView = fromVC.view;
//    UIView* toView   = toVC.view;

    //Setup fromView
    CGRect fromViewStartFrame = fromView.frame;
    CGRect fromViewFinalFrame = fromViewStartFrame;
    fromViewFinalFrame.origin.y = CGRectGetHeight(containerView.bounds);
    fromView.frame              = fromViewStartFrame;
    [containerView addSubview:fromView];

    self.isPresenting = YES;
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromView.frame = fromViewFinalFrame;
    } completion:^(BOOL finished) {
        self.isPresenting = NO;
        self.isPresented = [transitionContext transitionWasCancelled];
        [self addPresentGestureRecoginizer];

        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)performAnimations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
    if (self.interactionInProgress) {
        [UIView animateWithDuration:self.nonInteractiveDuration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear animations:^{
            if (animations) {
                animations();
            }
        } completion:^(BOOL finished) {
            if (completion) {
                completion(finished);
            }
        }];
    } else {
        [UIView animateWithDuration:self.nonInteractiveDuration delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:0 animations:^{
            if (animations) {
                animations();
            }
        } completion:^(BOOL finished) {
            if (completion) {
                completion(finished);
            }
        }];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    return YES;
}

#pragma mark - Gestures

- (void)addPresentGestureRecoginizer {
    if (self.isPresented) {
        return;
    }

    if (self.dismissGestureRecognizer) {
        [self.presentedViewController.view removeGestureRecognizer:self.dismissGestureRecognizer];
        self.dismissGestureRecognizer.delegate = nil;
        self.dismissGestureRecognizer          = nil;
    }

    if (!self.presentGestureRecognizer) {
        self.presentGestureRecognizer          = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePresentGesture:)];
        self.presentGestureRecognizer.delegate = self;
        [self.presentedViewController.view addGestureRecognizer:self.presentGestureRecognizer];
    }
}

- (void)addDismissGestureRecognizer {
    if (!self.isPresented) {
        return;
    }

    if (self.presentGestureRecognizer) {
        [self.presentedViewController.view removeGestureRecognizer:self.presentGestureRecognizer];
        self.presentGestureRecognizer.delegate = nil;
        self.presentGestureRecognizer          = nil;
    }

    if (!self.dismissGestureRecognizer) {
        self.dismissGestureRecognizer          = (id)[[WMFScrollViewTopPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissGesture:)];
        self.dismissGestureRecognizer.delegate = self;
        [self.presentedViewController.view addGestureRecognizer:self.dismissGestureRecognizer];
        [self.dismissGestureRecognizer setScrollview:self.scrollView];
    }
}

- (void)handlePresentGesture:(UIPanGestureRecognizer*)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            break;
        }

        case UIGestureRecognizerStateChanged: {
            CGPoint distanceTraveled = [recognizer locationInView:recognizer.view];
            CGFloat percent          = distanceTraveled.y / self.totalCardAnimationDistance;
            percent = 1 - percent;

            if (percent > 0.99) {
                percent = 0.99;
            }

            [self updateInteractiveTransition:percent];
            break;
        }

        case UIGestureRecognizerStateEnded: {
            CGPoint velocity = [recognizer velocityInView:recognizer.view];

            BOOL fastSwipeUp = velocity.y < -self.totalCardAnimationDistance;
            if (fastSwipeUp) {
                [self finishInteractiveTransition];
                return;
            }

            BOOL fastSwipeDown = velocity.y > self.totalCardAnimationDistance;
            if (fastSwipeDown) {
                [self cancelInteractiveTransition];
                return;
            }

            if (self.percentComplete > 0.60) {
                [self finishInteractiveTransition];
                return;
            }

            if (self.percentComplete > 0.25) {
                [self animateToPopupPosition];
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
            CGPoint distanceTraveled = [recognizer translationInView:recognizer.view];
            CGFloat percent          = distanceTraveled.y / self.totalCardAnimationDistance;
            if (percent > 0.99) {
                percent = 0.99;
            }

            [self updateInteractiveTransition:percent];

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

- (void)handleBackgroundTap:(UITapGestureRecognizer*)tap {
    [self cancelInteractiveTransition];
}

@end
