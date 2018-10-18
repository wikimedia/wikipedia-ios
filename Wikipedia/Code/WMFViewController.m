#import "WMFViewController.h"
#import "Wikipedia-Swift.h"
#import "UIViewController+WMFEmptyView.h"

@interface WMFViewController () <WMFEmptyViewContainer>
@property (nonatomic, strong) WMFNavigationBar *navigationBar;
@property (nonatomic, strong) WMFNavigationBarHider *navigationBarHider;
@property (nonatomic) BOOL showsNavigationBar;
@end

@implementation WMFViewController

- (void)setup {
    self.theme = [WMFTheme standard];
    self.navigationBar = [[WMFNavigationBar alloc] initWithFrame:CGRectZero];
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
    [self applyTheme:self.theme];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.showsNavigationBar = self.parentViewController == self.navigationController && self.navigationController.isNavigationBarHidden;

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

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    [self updateScrollViewInsets];
}

- (void)scrollViewInsetsDidChange {
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.navigationBar layoutIfNeeded];
        [self updateScrollViewInsets];
    } completion:NULL];
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

    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    CGFloat top = CGRectGetMaxY(frame);
    CGFloat bottom = safeInsets.bottom;

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
    if ([self.scrollView wmf_setContentInset:contentInset scrollIndicatorInsets:scrollIndicatorInsets preserveContentOffset:YES]) {
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

@end
