#import "WMFThemeableNavigationController.h"
#import "WMFAppViewController.h"
#import "Wikipedia-Swift.h"

@interface WMFThemeableNavigationController ()

@property (nonatomic, strong) WMFTheme *theme;
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self.themeableNavigationControllerDelegate themeableNavigationControllerTraitCollectionDidChange:self];
}

@end
