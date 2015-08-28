
#import "WMFPreviewController.h"
#import "WMFArticleContainerViewController.h"
#import "UITabBarController+WMFExtensions.h"

@interface WMFPreviewController ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UIViewController* previewViewController;
@property (nonatomic, strong, readwrite) UIViewController* presentingViewController;
@property (nonatomic, strong, readwrite) UITabBarController* tabBarController;

@property (nonatomic, strong) UIView* containerView;
@property (nonatomic, strong) UIView* presentingViewControllerSnapshot;

@property (nonatomic, strong) UIView* gestureView;

@property (strong, nonatomic) UITapGestureRecognizer* tapGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer* panGestureRecognizer;
@property (assign, nonatomic) CGFloat yTouchOffsetFromPreviewOrigin;
@property (assign, nonatomic) CGPoint intitalPreviewTouchLocation;

@end

@implementation WMFPreviewController

- (instancetype)initWithPreviewViewController:(UIViewController*)previewViewController presentingViewController:(UIViewController*)presentingController tabBarController:(UITabBarController*)tabBarController {
    self = [super init];
    if (self) {
        self.previewHeight            = 300.0;
        self.previewViewController    = previewViewController;
        self.presentingViewController = presentingController;
        self.tabBarController         = tabBarController;
        [self setupViews];
        [self setupGestureRecognizers];
    }
    return self;
}

- (void)setupViews {
    UIView* view = [[UIView alloc] initWithFrame:self.presentingViewController.view.bounds];
    view.backgroundColor = [UIColor blackColor];

    self.containerView = view;

    view       = [self.presentingViewController.view snapshotViewAfterScreenUpdates:YES];
    view.frame = self.containerView.bounds;
    [self.containerView addSubview:view];
    self.presentingViewControllerSnapshot = view;

    self.previewViewController.view.frame = self.containerView.bounds;
    [self setPreviewVerticalOffset:self.containerView.bounds.size.height];
    [self.containerView addSubview:self.previewViewController.view];

    view                 = [[UIView alloc] initWithFrame:self.presentingViewController.view.bounds];
    view.backgroundColor = [UIColor clearColor];
    [self.containerView addSubview:view];

    self.gestureView = view;
}

- (void)setupGestureRecognizers {
    self.panGestureRecognizer =
        [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    self.panGestureRecognizer.delegate = self;
    [self.gestureView addGestureRecognizer:self.panGestureRecognizer];

    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.gestureView addGestureRecognizer:self.tapGestureRecognizer];
}

#pragma mark - Preview Offset

- (CGFloat)startingVerticalOffset {
    return self.containerView.bounds.size.height - self.previewHeight;
}

- (CGFloat)offScreenVerticalOffset {
    return self.containerView.bounds.size.height;
}

- (CGFloat)presentedVerticalOffset {
    return 0.0;
}

- (void)setPreviewVerticalOffset:(CGFloat)verticalOffset animated:(BOOL)animated completion:(dispatch_block_t)completion {
    if (animated) {
        [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self updateBackgroundWithPercentCompletion:[self percentCompleteWithVerticalOffset:verticalOffset]];
        } completion:NULL];

        [UIView animateWithDuration:0.35 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:0 animations:^{
            [self setPreviewVerticalOffset:verticalOffset];
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    } else {
        [self updateBackgroundWithPercentCompletion:[self percentCompleteWithVerticalOffset:verticalOffset]];
        [self setPreviewVerticalOffset:verticalOffset];
        if (completion) {
            completion();
        }
    }
}

- (void)setPreviewVerticalOffset:(CGFloat)verticalOffset {
    CGRect frame = self.containerView.bounds;
    frame                                 = CGRectOffset(frame, 0.0, verticalOffset);
    self.previewViewController.view.frame = frame;
}

#pragma mark - Preview Management

- (void)presentPreviewAnimated:(BOOL)animated {
    [self.presentingViewController addChildViewController:self.previewViewController];
    [self.presentingViewController.view addSubview:self.containerView];

    [self.tabBarController wmf_setTabBarVisible:NO animated:animated completion:^{
        @weakify(self);
        [self setPreviewVerticalOffset:[self startingVerticalOffset] animated:animated completion:^{
            @strongify(self);
            [self.previewViewController didMoveToParentViewController:self.presentingViewController];
        }];
    }];
}

- (void)resetPreviewAnimated:(BOOL)animated {
    [self setPreviewVerticalOffset:[self startingVerticalOffset] animated:animated completion:NULL];
}

- (void)cancelPreviewAnimated:(BOOL)animated {
    @weakify(self);
    [self setPreviewVerticalOffset:[self offScreenVerticalOffset] animated:animated completion:^{
        @strongify(self);
        [self.previewViewController willMoveToParentViewController:nil];
        [self.containerView removeFromSuperview];
        [self.previewViewController removeFromParentViewController];
        [self.tabBarController wmf_setTabBarVisible:YES animated:animated completion:NULL];
        [self.delegate previewController:self didDismissViewController:self.previewViewController];
    }];
}

- (void)completePreviewAnimated:(BOOL)animated {
    @weakify(self);
    [self setPreviewVerticalOffset:[self presentedVerticalOffset] animated:animated completion:^{
        @strongify(self);
        [self.previewViewController willMoveToParentViewController:nil];
        [self.containerView removeFromSuperview];
        [self.previewViewController removeFromParentViewController];
        [self.tabBarController wmf_setTabBarVisible:YES animated:animated completion:NULL];
        [self.delegate previewController:self didPresentViewController:self.previewViewController];
    }];
}

- (CGFloat)percentCompleteWithVerticalOffset:(CGFloat)yOffset {
    return 1 - (yOffset / ([self offScreenVerticalOffset] - [self presentedVerticalOffset]));
}

- (void)updateBackgroundWithPercentCompletion:(CGFloat)percent {
    CGFloat scaleAt1 = 0.92;
    CGFloat scaleAt0 = 1.0;

    CGFloat totalScaleChange = scaleAt1 - scaleAt0;
    CGFloat scaleChange      = percent * totalScaleChange;
    CGFloat scale            = scaleAt0 + scaleChange;
    self.presentingViewControllerSnapshot.layer.transform = CATransform3DMakeScale(scale, scale, 1.0);
}

#pragma mark - Gesture Recognizer

- (void)handlePanGesture:(UIPanGestureRecognizer*)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint touchlocation = [recognizer locationInView:self.containerView];
            self.intitalPreviewTouchLocation = touchlocation;
            CGPoint viewLocation = self.previewViewController.view.frame.origin;
            self.yTouchOffsetFromPreviewOrigin = viewLocation.y - touchlocation.y;
            break;
        }

        case UIGestureRecognizerStateChanged: {
            CGPoint touchlocation = [recognizer locationInView:self.containerView];
            CGFloat newYOffest    = touchlocation.y + self.yTouchOffsetFromPreviewOrigin;
            newYOffest = newYOffest > [self presentedVerticalOffset] ? newYOffest : [self presentedVerticalOffset];
            CGRect newFrame = self.previewViewController.view.frame;
            newFrame.origin.y                     = newYOffest;
            self.previewViewController.view.frame = newFrame;
            [self updateBackgroundWithPercentCompletion:[self percentCompleteWithVerticalOffset:newYOffest]];
            break;
        }

        case UIGestureRecognizerStateEnded: {
            CGPoint velocity = [recognizer velocityInView:self.containerView];

            BOOL fastSwipeUp = velocity.y < -(self.intitalPreviewTouchLocation.y);
            if (fastSwipeUp) {
                [self completePreviewAnimated:YES];
                return;
            }

            BOOL fastSwipeDown = velocity.y > self.intitalPreviewTouchLocation.y;
            if (fastSwipeDown) {
                [self cancelPreviewAnimated:YES];
                return;
            }

            CGPoint touchlocation = [recognizer locationInView:self.containerView];

            if (touchlocation.y < (0.6 * self.intitalPreviewTouchLocation.y)) {
                [self completePreviewAnimated:YES];
                return;
            }

            if (touchlocation.y < self.intitalPreviewTouchLocation.y) {
                [self resetPreviewAnimated:YES];
                return;
            }

            [self cancelPreviewAnimated:YES];
            break;
        }

        default:
            [self cancelPreviewAnimated:YES];
            break;
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer*)recognizer {
    CGPoint touchlocation = [recognizer locationInView:self.containerView];
    CGFloat topInset      = [self.presentingViewController.navigationController.navigationBar frame].size.height
                            + [[UIApplication sharedApplication] statusBarFrame].size.height;
    CGRect frame = CGRectOffset(self.previewViewController.view.frame, 0.0, topInset);

    if (CGRectContainsPoint(frame, touchlocation)) {
        [self completePreviewAnimated:YES];
    } else {
        [self cancelPreviewAnimated:YES];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    return YES;
}

@end
