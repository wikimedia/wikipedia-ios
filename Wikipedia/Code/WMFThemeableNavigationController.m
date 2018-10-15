#import "WMFThemeableNavigationController.h"

@interface WMFThemeableNavigationController ()

@property (nonatomic, strong) WMFTheme *theme;

@end

@implementation WMFThemeableNavigationController

- (instancetype)initWithRootViewController:(UIViewController<WMFThemeable> *)rootViewController theme:(WMFTheme *)theme {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.theme = theme;
        [self applyTheme:theme];
        [rootViewController applyTheme:theme];
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.theme.preferredStatusBarStyle;
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    self.navigationBar.barTintColor = theme.colors.chromeBackground;
    self.navigationBar.translucent = NO;
    self.navigationBar.tintColor = theme.colors.chromeText;
    [self.navigationBar setBackgroundImage:theme.navigationBarBackgroundImage forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setTitleTextAttributes:theme.navigationBarTitleTextAttributes];

    self.toolbar.barTintColor = theme.colors.chromeBackground;
    self.toolbar.translucent = NO;
    self.view.tintColor = theme.colors.link;
    [self setNeedsStatusBarAppearanceUpdate];
}

@end
