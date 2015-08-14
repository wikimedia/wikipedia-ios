#import "WMFArticlePopupTransition.h"
#import <BlocksKit/BlocksKit+UIKit.h>

#import "WMFArticleContainerViewController.h"
#import "WMFArticleViewController.h"
#import <PiwikTracker/PiwikTracker.h>
#import "MWKArticle+WMFAnalyticsLogging.h"

#import "WMFMath.h"

#import "WMFScrollViewTopPanGestureRecognizer.h"
#import "UIScrollView+WMFContentOffsetUtils.h"

@interface WMFArticlePopupTransition ()<UIGestureRecognizerDelegate>

@property (nonatomic, weak, readwrite) UIViewController* presentingViewController;

@property (nonatomic, strong, readwrite) UIView* backgroundView;
@property (nonatomic, weak, readwrite) UIView* containerView;

@property (nonatomic, assign, readwrite) BOOL isPresented;
@property (nonatomic, assign, readwrite) BOOL isDismissing;
@property (nonatomic, assign, readwrite) BOOL isPresenting;

@property (strong, nonatomic) UITapGestureRecognizer* tapGestureRecognizer;

@property (strong, nonatomic) UIPanGestureRecognizer* presentGestureRecognizer;
@property (strong, nonatomic) WMFScrollViewTopPanGestureRecognizer* dismissGestureRecognizer;
@property (assign, nonatomic) CGFloat yTouchOffset;

@property (assign, nonatomic) BOOL interactionInProgress;

@property (nonatomic, readonly) CGFloat popupOriginY;

@property (assign, nonatomic) CGFloat popupAnimationSpeed;
@property (assign, nonatomic) CGFloat popupAnimationStartTime;
@property (assign, nonatomic) CGFloat popupHeightAsProgress;
@property (assign, nonatomic) CGFloat totalCardAnimationDistance;

@end

@implementation WMFArticlePopupTransition

- (instancetype)initWithPresentingViewController:(UIViewController* __nonnull)presentingViewController {
    self = [super init];
    if (self) {
        self.presentingViewController = presentingViewController;
        _presentInteractively         = YES;
        _dismissInteractively         = YES;
        _popupHeight                  = 300.0;
        _popupAnimationSpeed          = 100 / 0.3;
        _nonInteractiveDuration       = 0.5;
    }
    return self;
}

- (CGFloat)popupOriginY {
    return (self.containerView.frame.size.height - self.popupHeight);
}

- (void)setIsPresenting:(BOOL)isPresenting {
    self.isDismissing = !isPresenting;
}

- (BOOL)isPresenting {
    return !self.isDismissing;
}

#pragma mark - UIViewAnimatedTransistioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return self.nonInteractiveDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    self.totalCardAnimationDistance = CGRectGetHeight([transitionContext containerView].frame);

    if (self.isDismissing) {
        [self animateDismiss:transitionContext];
    } else {
        if (self.presentInteractively) {
            [self.presentedViewController setMode:WMFArticleControllerModePopup animated:NO];
        }
        [self animatePresentation:transitionContext];
    }
}

#pragma mark - UIViewControllerInteractiveTransitioning

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    // !!!: this needs to happen before super because it is used to modify the animations that start in the super call
    self.interactionInProgress = YES;
    [super startInteractiveTransition:transitionContext];

    self.containerView = [transitionContext containerView];

    if (self.isPresenting) {
        // Animate the transition partially to get the view on screen
        [self animateToPopupPosition];
    }
}

- (UIViewAnimationCurve)completionCurve {
    return UIViewAnimationCurveLinear;
}

#pragma mark - Animation

- (CGFloat)animationProgressFromHeight:(CGFloat)height {
    return height / self.totalCardAnimationDistance;
}

- (CGFloat)yOffsetFromAnimationProgress:(CGFloat)progress {
    return self.totalCardAnimationDistance - (progress * self.totalCardAnimationDistance);
}

- (void)animateToPopupPosition {
    self.popupHeightAsProgress   = [self animationProgressFromHeight:self.popupHeight];
    self.popupAnimationStartTime = CACurrentMediaTime();
    CADisplayLink* popupAnimationTimer =
        [CADisplayLink displayLinkWithTarget:self selector:@selector(animatePopupWithTimer:)];
    [popupAnimationTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)animatePopupWithTimer:(CADisplayLink*)link {
    NSTimeInterval elapedTime = link.timestamp - self.popupAnimationStartTime;
    CGFloat distance          = elapedTime * self.popupAnimationSpeed;
    CGFloat progressDelta     = [self animationProgressFromHeight:distance];

    CGFloat percentComplete = [self percentComplete];

    if (percentComplete < self.popupHeightAsProgress) {
        percentComplete += progressDelta;
        if (percentComplete >= self.popupHeightAsProgress) {
            percentComplete = self.popupHeightAsProgress;
            [link invalidate];
            link = nil;
        }
    } else {
        percentComplete -= progressDelta;
        if (percentComplete <= self.popupHeightAsProgress) {
            percentComplete = self.popupHeightAsProgress;
            [link invalidate];
            link = nil;
        }
    }

    [self updateInteractiveTransition:percentComplete];
}

- (void)animatePresentation:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView* containerView  = [transitionContext containerView];
    UIViewController* toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView* toView         = [transitionContext viewForKey:UITransitionContextToViewKey];

    if (!self.backgroundView) {
        UIView* backgroundView = [[UIView alloc] initWithFrame:containerView.bounds];
        backgroundView.backgroundColor        = [UIColor blackColor];
        backgroundView.alpha                  = 0.35;
        backgroundView.userInteractionEnabled = NO;
        self.backgroundView                   = backgroundView;
    }

    // Setup toView
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toVC];

    [containerView addSubview:self.backgroundView];
    [containerView addSubview:toView];
    toView.frame = CGRectOffset(containerView.bounds, 0, containerView.frame.size.height);

    [self setupPresentationGestureIfNeeded];

    self.tapGestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.presentingViewController.view.window addGestureRecognizer:self.tapGestureRecognizer];

    [self performAnimations:^{
        self.backgroundView.alpha = 0.8;
        toView.frame = toViewFinalFrame;
    }
                 completion:^(BOOL finished) {
        self.isPresenting = [transitionContext transitionWasCancelled];
        self.isPresented = ![transitionContext transitionWasCancelled];
        [self.backgroundView removeFromSuperview];
        if (![transitionContext transitionWasCancelled]) {
            [self setupDismissalGestureIfNeeded];
            [self.presentedViewController setMode:WMFArticleControllerModeNormal animated:NO];
        }
        [self removePresentGestureRecognizer];

        [self.tapGestureRecognizer.view removeGestureRecognizer:self.tapGestureRecognizer];
        self.tapGestureRecognizer.delegate = nil;
        self.tapGestureRecognizer = nil;

        self.interactionInProgress = NO;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)animateDismiss:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView* containerView = [transitionContext containerView];
    UIView* fromView      = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView* toView        = [transitionContext viewForKey:UITransitionContextToViewKey];

    [containerView addSubview:toView];
    [containerView addSubview:self.backgroundView];
    [containerView addSubview:fromView];
    fromView.frame = containerView.bounds;

    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        self.backgroundView.alpha = 0.0;
        fromView.frame = CGRectOffset(containerView.bounds, 0, containerView.frame.size.height);
    } completion:^(BOOL finished) {
        self.interactionInProgress = NO;
        self.isDismissing = [transitionContext transitionWasCancelled];
        self.isPresented = [transitionContext transitionWasCancelled];
        [self.backgroundView removeFromSuperview];
        if (![transitionContext transitionWasCancelled]) {
            [self removeDismissGestureRecognizer];
            [self.presentedViewController setMode:WMFArticleControllerModePopup animated:NO];
        }
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)performAnimations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
    if (self.interactionInProgress) {
        [UIView animateWithDuration:self.nonInteractiveDuration
                              delay:0.0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
            if (animations) {
                animations();
            }
        }
                         completion:^(BOOL finished) {
            if (completion) {
                completion(finished);
            }
        }];
    } else {
        [UIView animateWithDuration:self.nonInteractiveDuration
                              delay:0.0
             usingSpringWithDamping:0.8
              initialSpringVelocity:0.0
                            options:0
                         animations:^{
            if (animations) {
                animations();
            }
        }
                         completion:^(BOOL finished) {
            if (completion) {
                completion(finished);
            }
        }];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer == self.presentGestureRecognizer) {
        // only start dragging popup when touch begins inside it
        CGPoint currentLocation = [gestureRecognizer locationInView:self.containerView];
        return currentLocation.y >= self.popupOriginY;
    } else if (gestureRecognizer == self.tapGestureRecognizer || gestureRecognizer == self.dismissGestureRecognizer) {
        // only start dismissal if our VC on top of the stack
        return self.presentingViewController.navigationController.topViewController == self.presentedViewController;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    return NO;
}

#pragma mark - Gestures

- (void)removeDismissGestureRecognizer {
    if (self.dismissGestureRecognizer) {
        [self.dismissGestureRecognizer.view removeGestureRecognizer:self.dismissGestureRecognizer];
        self.dismissGestureRecognizer.delegate = nil;
        self.dismissGestureRecognizer          = nil;
    }
}

- (void)removePresentGestureRecognizer {
    if (self.presentGestureRecognizer) {
        [self.presentGestureRecognizer.view removeGestureRecognizer:self.presentGestureRecognizer];
        self.presentGestureRecognizer.delegate = nil;
        self.presentGestureRecognizer          = nil;
    }
}

/**
 *  Idempotently setup the gesture recognizer for presenting from the popup state.
 */
- (void)setupPresentationGestureIfNeeded {
    if (self.isDismissing) {
        DDLogInfo(@"Not setting up presentation gesture while pending dismissal.");
        return;
    }
    if (self.presentInteractively && !self.presentGestureRecognizer) {
        self.presentGestureRecognizer =
            [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePresentGesture:)];
        self.presentGestureRecognizer.delegate = self;
        /*
           !!!: gesture must be added to window because:
           1. navigation controller disables user interaction for the containerView during transitions
           2. as a result of 1, the gesture never is never able to start receiving touch events, since the usual flow is
            for the gesture itself to start receiving events, _then_ start the transition
         */
        [self.presentingViewController.view.window addGestureRecognizer:self.presentGestureRecognizer];
    } else if (!self.presentInteractively) {
        [self removePresentGestureRecognizer];
    }
}

/**
 *  Idempotently setup gesture recognizer for dismissal from presented state.
 */
- (void)setupDismissalGestureIfNeeded {
    if (self.isPresenting) {
        DDLogInfo(@"Not setting up dismissal gesture while pending presentation.");
        return;
    }
    if (self.dismissInteractively && !self.dismissGestureRecognizer) {
        self.dismissGestureRecognizer =
            [[WMFScrollViewTopPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissGesture:)];
        self.dismissGestureRecognizer.cancelsTouchesInView = NO;
        self.dismissGestureRecognizer.delaysTouchesBegan   = NO;
        self.dismissGestureRecognizer.delegate             = self;
        [self.presentedViewController.view addGestureRecognizer:self.dismissGestureRecognizer];
        self.dismissGestureRecognizer.scrollView = self.presentedViewController.articleViewController.tableView;
    } else if (!self.dismissInteractively) {
        [self removeDismissGestureRecognizer];
    }
}

- (void)handlePresentGesture:(UIPanGestureRecognizer*)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint touchlocation = [recognizer locationInView:self.containerView];
            CGFloat viewLocation  = [self yOffsetFromAnimationProgress:self.percentComplete];
            self.yTouchOffset = viewLocation - touchlocation.y;
            break;
        }

        case UIGestureRecognizerStateChanged: {
            CGPoint distanceTraveled = [recognizer locationInView:self.containerView];
            distanceTraveled.y = distanceTraveled.y + self.yTouchOffset;
            CGFloat percent = distanceTraveled.y / self.totalCardAnimationDistance;
            percent = 1 - percent;

            if (percent > 0.99) {
                percent = 0.99;
            }

            [self updateInteractiveTransition:percent];
            break;
        }

        case UIGestureRecognizerStateEnded: {
            CGPoint velocity = [recognizer velocityInView:self.containerView];

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

- (void)handleDismissGesture:(WMFScrollViewTopPanGestureRecognizer*)recognizer {
    NSAssert(self.isDismissing, @"isDimissing flag was not set after presentation!");
    switch (recognizer.state) {
        case UIGestureRecognizerStateChanged: {
            if (recognizer.isRecordingVerticalDisplacement) {
                CGFloat transitionProgress =
                    WMFStrictClamp(0.0, recognizer.aboveBoundsVerticalDisplacement / self.totalCardAnimationDistance, 1.0);
                if (!self.interactionInProgress) {
                    /*
                       !!!: Must set this flag here since the gesture recognizer callbacks will fire again, causing this
                          method to be entered before startInteractiveTransition is called, causing us to call pop
                          more than once.
                     */
                    DDLogVerbose(@"Starting dismissal.");
                    [self.presentedViewController.navigationController popViewControllerAnimated:YES];
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
            if (self.interactionInProgress) {
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
            if (self.interactionInProgress) {
                DDLogVerbose(@"Canceling interactive transition.");
                [self cancelInteractiveTransition];
            }
            break;
        }

        default:
            break;
    }
}

- (void)handleTap:(UITapGestureRecognizer*)tap {
    NSAssert(self.isPresenting, @"Tap gesture should only be possible while presenting.");
    if ([tap locationInView:self.containerView].y >= self.popupOriginY) {
        [self finishInteractiveTransition];
    } else {
        [self cancelInteractiveTransition];
    }
}

- (void)finishInteractiveTransition {
    if (self.isPresenting) {
        [[PiwikTracker sharedInstance] sendEventWithCategory:@"Preview" action:@"Open" name:[self.presentedViewController analyticsName] value:nil];
    }
    [super finishInteractiveTransition];
}

- (void)cancelInteractiveTransition {
    if (self.isPresenting) {
        [[PiwikTracker sharedInstance] sendEventWithCategory:@"Preview" action:@"Dismiss" name:[self.presentedViewController analyticsName] value:nil];
    }
    [super cancelInteractiveTransition];
}

@end
