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
    self.navigationBar.translucent = NO;
    self.navigationBar.tintColor = theme.colors.chromeText;
    UINavigationBarAppearance *appearance = [UINavigationBarAppearance appearanceForTheme:theme style:self.style];
    self.navigationBar.standardAppearance = appearance;
    self.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationBar.compactAppearance = appearance;
    
    NSString *themeName = [[NSUserDefaults standardUserDefaults] themeName];
    if ([WMFTheme isDefaultThemeName:themeName]) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
    } else if ([WMFTheme isDarkThemeName:themeName]) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    } else {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }

    if (self.style == WMFThemeableNavigationControllerStyleGallery) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self setNavigationBarHidden:YES animated:NO];
    }

    self.view.tintColor = theme.colors.link;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self.themeableNavigationControllerDelegate themeableNavigationControllerTraitCollectionDidChange:self];
}

@end
