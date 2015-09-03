
#import "WMFPreviewController.h"
#import "WMFArticleContainerViewController.h"
#import "UITabBarController+WMFExtensions.h"
#import <Masonry/Masonry.h>

@interface WMFPreviewController ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UIViewController* previewViewController;
@property (nonatomic, weak, readwrite) UIViewController* containingViewController;
@property (nonatomic, weak, readwrite) UITabBarController* tabBarController;

@property (nonatomic, strong) UIView* containerView;
@property (nonatomic, strong) UIView* gestureView;

@property (strong, nonatomic) UITapGestureRecognizer* tapGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer* panGestureRecognizer;
@property (assign, nonatomic) CGFloat yTouchOffsetFromPreviewOrigin;
@property (assign, nonatomic) CGPoint intitalPreviewTouchLocation;

@end

@implementation WMFPreviewController

- (instancetype)initWithPreviewViewController:(UIViewController*)previewViewController containingViewController:(UIViewController*)containingViewController tabBarController:(UITabBarController*)tabBarController {
    self = [super init];
    if (self) {
        self.previewViewController    = previewViewController;
        self.containingViewController = containingViewController;
        self.tabBarController         = tabBarController;
    }
    return self;
}

- (void)updatePreviewWithSizeChange:(CGSize)newSize {
    [self setPreviewVerticalOffset:[self startingVerticalOffset]];
}

#pragma amrk - Views

- (void)setupViews {
    //Add container for snapshots
    UIView* view = [[UIView alloc] initWithFrame:self.containingViewController.view.bounds];
    view.backgroundColor = [UIColor clearColor];
    [self.containingViewController.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.edges.equalTo(self.containingViewController.view);
    }];
    self.containerView = view;

    //Add preview
    [self.containingViewController addChildViewController:self.previewViewController];
    [self.containerView addSubview:self.previewViewController.view];
    [self setPreviewVerticalOffset:[self offScreenVerticalOffset]];
    [self.previewViewController didMoveToParentViewController:self.containingViewController];

    // Add gesture view
    view                 = [[UIView alloc] initWithFrame:self.containerView.bounds];
    view.backgroundColor = [UIColor clearColor];
    [self.containerView addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.edges.equalTo(self.containerView);
    }];
    self.gestureView = view;
}

- (void)tearDownViews {
    [self.previewViewController willMoveToParentViewController:nil];
    [self.previewViewController.view removeFromSuperview];
    [self.previewViewController removeFromParentViewController];
    [self.containerView removeFromSuperview];
    self.containingViewController.view.layer.transform = CATransform3DIdentity;
    self.previewViewController.view.layer.transform    = CATransform3DIdentity;
}

#pragma mark - Gesture Recognizer Setup

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
    if (self.containerView.bounds.size.height > 400) {
        return self.containerView.frame.size.height * 0.66;
    } else {
        return self.containerView.frame.size.height * 0.5;
    }
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

        [self setPreviewVerticalOffset:verticalOffset];
        [UIView animateWithDuration:0.35 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:0 animations:^{
            [self.previewViewController.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    } else {
        [self updateBackgroundWithPercentCompletion:[self percentCompleteWithVerticalOffset:verticalOffset]];
        [self setPreviewVerticalOffset:verticalOffset];
        [self.previewViewController.view layoutIfNeeded];
        if (completion) {
            completion();
        }
    }
}

- (void)setPreviewVerticalOffset:(CGFloat)verticalOffset {
    [self.previewViewController.view mas_remakeConstraints:^(MASConstraintMaker* make) {
        make.size.equalTo(self.containerView);
        make.leading.equalTo(self.containerView);
        make.top.equalTo(self.containerView).with.offset(verticalOffset);
    }];
}

#pragma mark - Preview Management

- (void)presentPreviewAnimated:(BOOL)animated {
    [self setupViews];
    [self setupGestureRecognizers];

    [self.tabBarController wmf_setTabBarVisible:NO animated:animated completion:^{
        [self setPreviewVerticalOffset:[self startingVerticalOffset] animated:animated completion:NULL];
    }];
}

- (void)resetPreviewAnimated:(BOOL)animated {
    [self setPreviewVerticalOffset:[self startingVerticalOffset] animated:animated completion:NULL];
}

- (void)cancelPreviewAnimated:(BOOL)animated {
    @weakify(self);
    [self setPreviewVerticalOffset:[self offScreenVerticalOffset] animated:animated completion:^{
        @strongify(self);
        [self tearDownViews];
        [self.tabBarController wmf_setTabBarVisible:YES animated:animated completion:NULL];
        [self.delegate previewController:self didDismissViewController:self.previewViewController];
    }];
}

- (void)completePreviewAnimated:(BOOL)animated {
    @weakify(self);
    [self setPreviewVerticalOffset:[self presentedVerticalOffset] animated:animated completion:^{
        @strongify(self);
        [self tearDownViews];
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
    self.containingViewController.view.layer.transform = CATransform3DMakeScale(scale, scale, 1.0);
    self.previewViewController.view.layer.transform    = CATransform3DInvert(self.containingViewController.view.layer.transform);
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
            [self setPreviewVerticalOffset:newYOffest];
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
    CGFloat topInset      = [self.containingViewController.navigationController.navigationBar frame].size.height
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
