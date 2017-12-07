#import "WMFViewController.h"
#import "Wikipedia-Swift.h"

@interface WMFViewController ()
@property (nonatomic, strong) NavigationBar *navigationBar;
@end

@implementation WMFViewController

- (void)setup {
    self.theme = [WMFTheme standard];
    self.navigationBar = [[NavigationBar alloc] initWithFrame:CGRectZero];
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
        
        [self navigationBarDidLoad];
    }
   
    [self updateNavigationBarStatusBarHeight];
}

- (void)navigationBarDidLoad {
    
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

- (void)updateScrollViewInsets {
    UIScrollView *scrollView = self.scrollView;
    CGRect frame = self.navigationBar.frame;
    UIView *superview = self.scrollView.superview;
    CGRect convertedFrame = [self.view convertRect:frame toView:superview];
    CGFloat top = CGRectGetMaxY(convertedFrame);
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
    if (wasAtTop) {
        scrollView.contentOffset = CGPointMake(0, 0 - scrollView.contentInset.top);
    }
}

#pragma mark - WMFThemeable

- (void)applyWithTheme:(WMFTheme *)theme {
    self.theme = theme;
    if (self.viewIfLoaded == nil) {
        return;
    }
    [self.navigationBar applyTheme:theme];
}

@end
