#import "WMFViewController.h"
#import "Wikipedia-Swift.h"
#import "UIViewController+WMFEmptyView.h"

static const NSTimeInterval WMFToolbarAnimationDuration = 0.3;
static const CGFloat WMFSecondToolbarSpacing = 8;
static const CGFloat WMFToolbarHeight = 44;
static const CGFloat WMFToolbarConstrainedHeight = 32;

@interface WMFViewController () <WMFEmptyViewContainer>
@property (nonatomic, strong) WMFNavigationBar *navigationBar;
@property (nonatomic, strong) WMFNavigationBarHider *navigationBarHider;
@property (nonatomic) BOOL showsNavigationBar;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIToolbar *secondToolbar;
@property (nonatomic, strong) NSLayoutConstraint *toolbarVisibleConstraint;
@property (nonatomic, strong) NSLayoutConstraint *toolbarHiddenConstraint;
@property (nonatomic, strong) NSLayoutConstraint *toolbarHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *secondToolbarVisibleConstraint;
@property (nonatomic, strong) NSLayoutConstraint *secondToolbarHiddenConstraint;
@property (nonatomic, strong) NSLayoutConstraint *secondToolbarHeightConstraint;
@end

@implementation WMFViewController

- (void)setup {
    self.theme = [WMFTheme standard];
    self.navigationBar = [[WMFNavigationBar alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self setupToolbars];
    [self applyTheme:self.theme];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.showsNavigationBar = ([self.parentViewController isKindOfClass:[UITabBarController class]] || self.parentViewController == self.navigationController) && self.navigationController.isNavigationBarHidden;

    if (self.showsNavigationBar) {
        if (self.navigationBar.superview == nil) {
            self.navigationBarHider = [[WMFNavigationBarHider alloc] init];
            self.navigationBarHider.navigationBar = self.navigationBar;
            self.navigationBarHider.delegate = self;

            self.navigationBar.delegate = self;
            self.navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
            [self.view addSubview:self.navigationBar];

            NSLayoutConstraint *topConstraint = [self.view.topAnchor constraintEqualToAnchor:self.navigationBar.topAnchor];
            NSLayoutConstraint *leadingConstraint = [self.view.leadingAnchor constraintEqualToAnchor:self.navigationBar.leadingAnchor];
            NSLayoutConstraint *trailingConstraint = [self.view.trailingAnchor constraintEqualToAnchor:self.navigationBar.trailingAnchor];

            [self.view addConstraints:@[topConstraint, leadingConstraint, trailingConstraint]];

            self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [self.navigationBar updateNavigationItems];
        self.navigationBar.navigationBarPercentHidden = 0;
    } else {
        if (self.navigationBar.superview) {
            [self.navigationBar removeFromSuperview];
            self.navigationBarHider = nil;
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateScrollViewInsets];
}

- (CGFloat)toolbarHeightForCurrentSafeAreaInsets {
    return self.view.safeAreaInsets.top == 0 ? WMFToolbarConstrainedHeight : WMFToolbarHeight;
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    self.toolbarHeightConstraint.constant = [self toolbarHeightForCurrentSafeAreaInsets];
    // self.secondToolbarHeightConstraint.constant = self.toolbarHeightConstraint.constant; // random button doesn't fit in 32 at the moment
    [self updateScrollViewInsets];
}

- (void)scrollViewInsetsDidChange {
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator
        animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            [self.navigationBar layoutIfNeeded];
            [self updateScrollViewInsets];
        }
                        completion:NULL];
}

- (void)updateScrollViewInsets {
    if (self.scrollView.contentInsetAdjustmentBehavior != UIScrollViewContentInsetAdjustmentNever) {
        return;
    }
    UIScrollView *scrollView = self.scrollView;
    if (!scrollView) {
        return;
    }

    CGRect frame = CGRectZero;
    if (self.showsNavigationBar) {
        frame = self.navigationBar.frame;
    } else if (self.navigationController) {
        frame = [self.navigationController.view convertRect:self.navigationController.navigationBar.frame toView:self.view];
    }

    CGFloat top = CGRectGetMaxY(frame);

    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    CGFloat bottom = safeInsets.bottom;
    if (!self.isToolbarHidden) {
        bottom += CGRectGetHeight(self.toolbar.frame);
    }

    UIEdgeInsets scrollIndicatorInsets;

    if (self.isSubtractingTopAndBottomSafeAreaInsetsFromScrollIndicatorInsets) {
        scrollIndicatorInsets = UIEdgeInsetsMake(top - safeInsets.top, safeInsets.left, bottom - safeInsets.bottom, safeInsets.right);
    } else {
        scrollIndicatorInsets = UIEdgeInsetsMake(top, safeInsets.left, bottom, safeInsets.right);
    }

    if (scrollView.refreshControl.isRefreshing) {
        top += scrollView.refreshControl.frame.size.height;
    }
    UIEdgeInsets contentInset = UIEdgeInsetsMake(top, 0, bottom, 0);

    if (UIEdgeInsetsEqualToEdgeInsets(contentInset, scrollView.contentInset) && UIEdgeInsetsEqualToEdgeInsets(scrollIndicatorInsets, scrollView.scrollIndicatorInsets)) {
        return;
    }
    if ([self.scrollView wmf_setContentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets preserveContentOffset:YES preserveAnimation:NO]) {
        [self scrollViewInsetsDidChange];
    }
}

- (void)scrollToTop {
    UIScrollView *scrollView = self.scrollView;
    if (!scrollView) {
        return;
    }
    [self.navigationBarHider scrollViewWillScrollToTop:scrollView];
    [scrollView setContentOffset:CGPointMake(0, 0 - scrollView.contentInset.top) animated:YES];
}

#pragma mark - WMFThemeable

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.theme.preferredStatusBarStyle;
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    if (self.viewIfLoaded == nil) {
        return;
    }
    [self.navigationBar applyTheme:theme];
    [self.toolbar setBackgroundImage:theme.navigationBarBackgroundImage forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    self.toolbar.translucent = NO;
    //[self.toolbar setShadowImage:theme.navigationBarShadowImage forToolbarPosition:UIBarPositionAny];
    [self.secondToolbar setBackgroundImage:theme.clearImage forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [self.secondToolbar setShadowImage:theme.clearImage forToolbarPosition:UIBarPositionAny];
    self.scrollView.refreshControl.tintColor = theme.colors.refreshControlTint;
}

#pragma mark - WMFNavigationBarHiderDelegate

- (void)navigationBarHider:(WMFNavigationBarHider *_Nonnull)hider didSetNavigationBarPercentHidden:(CGFloat)didSetNavigationBarPercentHidden underBarViewPercentHidden:(CGFloat)underBarViewPercentHidden extendedViewPercentHidden:(CGFloat)extendedViewPercentHidden animated:(BOOL)animated {
}

#pragma mark - WMFEmptyViewContainer

- (void)addEmptyView:(UIView *)emptyView {
    if (self.navigationBar.superview == self.view) {
        [self.view insertSubview:emptyView belowSubview:self.navigationBar];
    } else {
        [self.view addSubview:emptyView];
    }
}

#pragma mark - Toolbars

- (void)setupToolbars {
    self.toolbar = [[UIToolbar alloc] init];
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.toolbar];
    self.toolbarHeightConstraint = [self.toolbar.heightAnchor constraintEqualToConstant:[self toolbarHeightForCurrentSafeAreaInsets]];
    self.toolbarVisibleConstraint = [self.view.safeAreaLayoutGuide.bottomAnchor constraintEqualToAnchor:self.toolbar.bottomAnchor];
    self.toolbarHiddenConstraint = [self.view.bottomAnchor constraintEqualToAnchor:self.toolbar.topAnchor];
    NSLayoutConstraint *leadingConstraint = [self.view.leadingAnchor constraintEqualToAnchor:self.toolbar.leadingAnchor];
    NSLayoutConstraint *trailingConstraint = [self.toolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor];

    self.secondToolbar = [[UIToolbar alloc] init];
    self.secondToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.secondToolbar belowSubview:self.toolbar];
    self.secondToolbarHeightConstraint = [self.secondToolbar.heightAnchor constraintEqualToConstant:WMFToolbarHeight];
    self.secondToolbarVisibleConstraint = [self.secondToolbar.bottomAnchor constraintEqualToAnchor:self.toolbar.topAnchor constant:0 - WMFSecondToolbarSpacing];
    self.secondToolbarHiddenConstraint = [self.secondToolbar.topAnchor constraintEqualToAnchor:self.toolbar.topAnchor];
    NSLayoutConstraint *secondLeadingConstraint = [self.view.leadingAnchor constraintEqualToAnchor:self.secondToolbar.leadingAnchor];
    NSLayoutConstraint *secondTrailingConstraint = [self.secondToolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor];

#if DEBUG
    NSString *className = NSStringFromClass([self class]);
    self.toolbarHeightConstraint.identifier = [@[className, @"toolbarHeight"] componentsJoinedByString:@"-"];
    self.toolbarVisibleConstraint.identifier = [@[className, @"toolbarVisible"] componentsJoinedByString:@"-"];
    self.toolbarHiddenConstraint.identifier = [@[className, @"toolbarHidden"] componentsJoinedByString:@"-"];
    self.secondToolbarHeightConstraint.identifier = [@[className, @"secondToolbarHeight"] componentsJoinedByString:@"-"];
    self.secondToolbarVisibleConstraint.identifier = [@[className, @"secondToolbarVisible"] componentsJoinedByString:@"-"];
    self.secondToolbarHiddenConstraint.identifier = [@[className, @"secondToolbarHidden"] componentsJoinedByString:@"-"];
#endif

    [NSLayoutConstraint activateConstraints:@[self.toolbarHeightConstraint, self.secondToolbarHeightConstraint, self.toolbarHiddenConstraint, leadingConstraint, trailingConstraint, self.secondToolbarHiddenConstraint, secondLeadingConstraint, secondTrailingConstraint]];
}

- (BOOL)isToolbarHidden {
    return self.toolbarHiddenConstraint.isActive;
}

- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated {
    dispatch_block_t animations = ^{
        if (hidden) {
            [NSLayoutConstraint deactivateConstraints:@[self.toolbarVisibleConstraint]];
            [NSLayoutConstraint activateConstraints:@[self.toolbarHiddenConstraint]];
        } else {
            [NSLayoutConstraint deactivateConstraints:@[self.toolbarHiddenConstraint]];
            [NSLayoutConstraint activateConstraints:@[self.toolbarVisibleConstraint]];
        }
        [self.view layoutIfNeeded];
    };
    if (animated) {
        [UIView animateWithDuration:WMFToolbarAnimationDuration animations:animations];
    } else {
        animations();
    }
}

- (BOOL)isSecondToolbarHidden {
    return self.secondToolbarHiddenConstraint.isActive;
}

- (void)setSecondToolbarHidden:(BOOL)hidden animated:(BOOL)animated {
    dispatch_block_t animations = ^{
        if (hidden) {
            [NSLayoutConstraint deactivateConstraints:@[self.secondToolbarVisibleConstraint]];
            [NSLayoutConstraint activateConstraints:@[self.secondToolbarHiddenConstraint]];
        } else {
            [NSLayoutConstraint deactivateConstraints:@[self.secondToolbarHiddenConstraint]];
            [NSLayoutConstraint activateConstraints:@[self.secondToolbarVisibleConstraint]];
        }
        [self.view layoutIfNeeded];
    };
    if (animated) {
        [UIView animateWithDuration:WMFToolbarAnimationDuration animations:animations];
    } else {
        animations();
    }
}

- (void)setAdditionalSecondToolbarSpacing:(CGFloat)spacing animated:(BOOL)animated {
    dispatch_block_t animations = ^{
        self.secondToolbarVisibleConstraint.constant = 0 - WMFSecondToolbarSpacing - spacing;
        [self.view layoutIfNeeded];
    };
    if (animated) {
        [UIView animateWithDuration:WMFToolbarAnimationDuration animations:animations];
    } else {
        animations();
    }
}

@end
