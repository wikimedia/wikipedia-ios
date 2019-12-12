#import "WMFThemeableNavigationController.h"
#import "WMFAppViewController.h"

@interface WMFThemeableNavigationController ()

@property (nonatomic, strong) WMFTheme *theme;
@property (nonatomic, readonly) UIImageView *splashView;
@property (nonatomic) WMFThemeableNavigationControllerStyle style;
@end

@implementation WMFThemeableNavigationController
@synthesize splashView = _splashView;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController theme:(WMFTheme *)theme style:(WMFThemeableNavigationControllerStyle)style {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.style = style;
        self.theme = theme;
        [self applyTheme:theme];
        self.modalPresentationStyle = UIModalPresentationOverFullScreen; // before removing this, ensure alert messages presented with RMessageView (or whatever replaced it) have the proper offset https://phabricator.wikimedia.org/T232604
        if ([rootViewController conformsToProtocol:@protocol(WMFThemeable)]) {
            [(id)rootViewController applyTheme:theme];
        }
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController theme:(WMFTheme *)theme {
    return [self initWithRootViewController:rootViewController theme:theme style:WMFThemeableNavigationControllerStyleDefault];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.theme.preferredStatusBarStyle;
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    self.navigationBar.barTintColor = theme.colors.chromeBackground;
    self.navigationBar.translucent = NO;
    self.navigationBar.tintColor = theme.colors.chromeText;
    UIImage *backgroundImage = nil;
    switch (self.style) {
        case WMFThemeableNavigationControllerStyleEditor:
            backgroundImage = theme.editorNavigationBarBackgroundImage;
            break;
        case WMFThemeableNavigationControllerStyleSheet:
            backgroundImage = theme.sheetNavigationBarBackgroundImage;
            break;
        case WMFThemeableNavigationControllerStyleGallery:
            self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self setNavigationBarHidden:YES animated:NO];
            break;
        default:
            backgroundImage = theme.navigationBarBackgroundImage;
            break;
    }
    [self.navigationBar setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setTitleTextAttributes:theme.navigationBarTitleTextAttributes];

    self.toolbar.barTintColor = theme.colors.chromeBackground;
    self.toolbar.translucent = NO;
    self.view.tintColor = theme.colors.link;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Splash

- (UIImageView *)splashView {
    if (!_splashView) {
        _splashView = [[UIImageView alloc] init];
        _splashView.contentMode = UIViewContentModeCenter;
        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
            [_splashView setImage:[UIImage imageNamed:@"splashscreen-background"]];
        }
        if (@available(iOS 13.0, *)) {
            _splashView.backgroundColor = [UIColor systemBackgroundColor];
        } else {
            _splashView.backgroundColor = [UIColor whiteColor];
        }
        [self.view wmf_addSubviewWithConstraintsToEdges:_splashView];
        UIImage *wordmark = [UIImage imageNamed:@"splashscreen-wordmark"];
        UIImageView *wordmarkView = [[UIImageView alloc] initWithImage:wordmark];
        wordmarkView.translatesAutoresizingMaskIntoConstraints = NO;
        [_splashView addSubview:wordmarkView];
        NSLayoutConstraint *centerXConstraint = [_splashView.centerXAnchor constraintEqualToAnchor:wordmarkView.centerXAnchor];
        NSLayoutConstraint *centerYConstraint = [_splashView.centerYAnchor constraintEqualToAnchor:wordmarkView.centerYAnchor constant:12];
        [_splashView addConstraints:@[centerXConstraint, centerYConstraint]];
    }
    return _splashView;
}

- (void)showSplashView {
    self.splashView.hidden = NO;
    self.splashView.alpha = 1.0;
}

- (void)showSplashViewIfNotShowing {
    if (!self.splashView.hidden) {
        return;
    }
    [self showSplashView];
}

- (void)hideSplashViewAnimated:(BOOL)animated {
    NSTimeInterval duration = animated ? 0.15 : 0.0;
    [UIView animateWithDuration:duration
        delay:0
        options:UIViewAnimationOptionAllowUserInteraction
        animations:^{
            self.splashView.alpha = 0.0;
        }
        completion:^(BOOL finished) {
            self.splashView.hidden = YES;
        }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self.themeableNavigationControllerDelegate themeableNavigationControllerTraitCollectionDidChange:self];
}

@end
