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
    self.automaticallyAdjustsScrollViewInsets = NO;
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
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

            self.automaticallyAdjustsScrollViewInsets = NO;
            if (@available(iOS 11.0, *)) {
                self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
        }
        [self.navigationBar updateNavigationItems];
        self.navigationBar.navigationBarPercentHidden = 0;
        [self updateNavigationBarStatusBarHeight];
    } else {
        if (self.navigationBar.superview) {
            [self.navigationBar removeFromSuperview];
            self.navigationBarHider = nil;
        }
    }
}

- (void)updateNavigationBarStatusBarHeight {
    if (!self.showsNavigationBar) {
        return;
    }

    if (@available(iOS 11.0, *)) {
        // automatically handled by safe area insets
    } else {
        CGFloat newHeight = self.navigationController.topLayoutGuide.length;
        if (newHeight != self.navigationBar.statusBarHeight) {
            self.navigationBar.statusBarHeight = newHeight;
            [self.view setNeedsLayout];
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateScrollViewInsets];
}

- (void)viewSafeAreaInsetsDidChange {
    if (@available(iOS 11.0, *)) {
        [super viewSafeAreaInsetsDidChange];
    }
    [self updateScrollViewInsets];
}

- (void)scrollViewInsetsDidChange {
}

- (void)updateScrollViewInsets {
    if (self.automaticallyAdjustsScrollViewInsets) {
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
    UIEdgeInsets safeInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeInsets = self.view.safeAreaInsets;
    } else {
        safeInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, MIN(44, self.bottomLayoutGuide.length), 0); // MIN 44 is a workaround for an iOS 10 only issue where the bottom layout guide is too tall when pushing from explore
    }
    CGFloat bottom = safeInsets.bottom;
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsMake(top, safeInsets.left, bottom, safeInsets.right);
    if (scrollView.refreshControl.isRefreshing) {
        top += scrollView.refreshControl.frame.size.height;
    }
    UIEdgeInsets contentInset = UIEdgeInsetsMake(top, 0, bottom, 0);
    if (UIEdgeInsetsEqualToEdgeInsets(contentInset, scrollView.contentInset) && UIEdgeInsetsEqualToEdgeInsets(scrollIndicatorInsets, scrollView.scrollIndicatorInsets)) {
        return;
    }
    if ([self.scrollView wmf_setContentInsetPreservingTopAndBottomOffset:contentInset scrollIndicatorInsets:scrollIndicatorInsets withNavigationBar:self.navigationBar]) {
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
