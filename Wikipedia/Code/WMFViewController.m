#import "WMFViewController.h"
#import "Wikipedia-Swift.h"

@interface WMFViewController ()
@property (nonatomic, strong) WMFNavigationBar *navigationBar;
@property (nonatomic, strong) WMFNavigationBarHider *navigationBarHider;
@end

@implementation WMFViewController

- (void)setup {
    self.theme = [WMFTheme standard];
    self.navigationBar = [[WMFNavigationBar alloc] initWithFrame:CGRectZero];
    self.navigationBarHider = [[WMFNavigationBarHider alloc] init];
    self.navigationBarHider.navigationBar = self.navigationBar;
    self.navigationBarHider.delegate = self;
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

- (BOOL)showsNavigationBar {
    return self.parentViewController == self.navigationController && self.navigationController.isNavigationBarHidden;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyTheme:self.theme];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.showsNavigationBar && self.navigationBar.superview == nil) {
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
    self.navigationBar.navigationBarPercentHidden = 0;
    [self updateNavigationBarStatusBarHeight];
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

- (void)didUpdateScrollViewInsets {
}

- (void)updateScrollViewInsets {
    UIScrollView *scrollView = self.scrollView;
    CGRect frame = self.navigationBar.frame;
    CGFloat top = CGRectGetMaxY(frame);
    if (scrollView.refreshControl.isRefreshing) {
        top += scrollView.refreshControl.frame.size.height;
    }
    UIEdgeInsets safeInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeInsets = self.view.safeAreaInsets;
    }
    CGFloat bottom = self.bottomLayoutGuide.length;
    UIEdgeInsets contentInset = UIEdgeInsetsMake(top, 0, bottom, 0);
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsMake(top, safeInsets.left, bottom, safeInsets.right);
    if (UIEdgeInsetsEqualToEdgeInsets(contentInset, scrollView.contentInset) && UIEdgeInsetsEqualToEdgeInsets(scrollIndicatorInsets, scrollView.scrollIndicatorInsets)) {
        return;
    }
    BOOL wasAtTop = scrollView.contentOffset.y == 0 - scrollView.contentInset.top;
    scrollView.contentInset = contentInset;
    scrollView.scrollIndicatorInsets = scrollIndicatorInsets;
    [self didUpdateScrollViewInsets];
    if (wasAtTop) {
        scrollView.contentOffset = CGPointMake(0, 0 - scrollView.contentInset.top);
        [self.navigationBar setPercentHidden:0 animated:NO];
    }
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

- (void)navigationBarHider:(WMFNavigationBarHider *_Nonnull)hider didSetNavigationBarPercentHidden:(CGFloat)didSetNavigationBarPercentHidden extendedViewPercentHidden:(CGFloat)extendedViewPercentHidden animated:(BOOL)animated {
}

@end
