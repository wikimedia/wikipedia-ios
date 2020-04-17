#import "WMFThemeableNavigationController.h"
#import "WMFAppViewController.h"
#import "Wikipedia-Swift.h"

@interface WMFThemeableNavigationController ()

@property (nonatomic, strong) WMFTheme *theme;
@property (nonatomic, nullable) WMFSplashScreenViewController *splashScreenViewController;
@property (nonatomic) WMFThemeableNavigationControllerStyle style;
@end

@implementation WMFThemeableNavigationController

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

- (void)showSplashView {
    if (self.splashScreenViewController) {
        return;
    }
    WMFSplashScreenViewController *splashVC = [[WMFSplashScreenViewController alloc] init];
    // Explicit appearance transitions need to be used here because UINavigationController overrides
    // a lot of behaviors when adding the VC as a child and causes layout issues for our use case.
    [splashVC beginAppearanceTransition:YES animated:NO];
    [self.view wmf_addSubviewWithConstraintsToEdges:splashVC.view];
    [splashVC endAppearanceTransition];
    self.splashScreenViewController = splashVC;
}

- (void)hideSplashViewAnimated:(BOOL)animated {
    if (!self.splashScreenViewController) {
        return;
    }
    WMFSplashScreenViewController *splashVC = self.splashScreenViewController;
    [splashVC ensureMinimumShowDurationWithCompletion:^{
        // Explicit appearance transitions need to be used here because UINavigationController overrides
        // a lot of behaviors when adding the VC as a child and causes layout issues for our use case.
        [splashVC beginAppearanceTransition:NO animated:YES];
        NSTimeInterval duration = animated ? 0.15 : 0.0;
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            splashVC.view.alpha = 0.0;
        } completion:^(BOOL finished) {
            [splashVC.view removeFromSuperview];
            [splashVC endAppearanceTransition];
        }];
    }];
    self.splashScreenViewController = nil;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self.themeableNavigationControllerDelegate themeableNavigationControllerTraitCollectionDidChange:self];
}

@end
