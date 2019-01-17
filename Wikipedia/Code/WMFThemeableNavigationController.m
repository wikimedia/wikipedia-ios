#import "WMFThemeableNavigationController.h"

@interface WMFThemeableNavigationController ()

@property (nonatomic, strong) WMFTheme *theme;
@property (nonatomic, getter=isEditorStyle) BOOL editorStyle;
@end

@implementation WMFThemeableNavigationController

- (instancetype)initWithRootViewController:(UIViewController<WMFThemeable> *)rootViewController theme:(WMFTheme *)theme isEditorStyle:(BOOL)isEditorStyle {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.editorStyle = isEditorStyle;
        self.theme = theme;
        [self applyTheme:theme];
        [rootViewController applyTheme:theme];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController<WMFThemeable> *)rootViewController theme:(WMFTheme *)theme {
    return [self initWithRootViewController:rootViewController theme:theme isEditorStyle:NO];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.theme.preferredStatusBarStyle;
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    self.navigationBar.barTintColor = theme.colors.chromeBackground;
    self.navigationBar.translucent = NO;
    self.navigationBar.tintColor = theme.colors.chromeText;
    if (self.isEditorStyle) {
        [self.navigationBar setBackgroundImage:theme.editorNavigationBarBackgroundImage forBarMetrics:UIBarMetricsDefault];

    } else {
        [self.navigationBar setBackgroundImage:theme.navigationBarBackgroundImage forBarMetrics:UIBarMetricsDefault];
    }
    [self.navigationBar setTitleTextAttributes:theme.navigationBarTitleTextAttributes];

    self.toolbar.barTintColor = theme.colors.chromeBackground;
    self.toolbar.translucent = NO;
    self.view.tintColor = theme.colors.link;
    [self setNeedsStatusBarAppearanceUpdate];
}

@end
