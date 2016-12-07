#import "WMFStyleManager.h"
#import "UIColor+WMFStyle.h"
#import "UIImage+WMFStyle.h"
#import "UITabBarItem+WMFStyling.h"

static WMFStyleManager *_styleManager = nil;

@implementation WMFStyleManager

+ (void)setSharedStyleManager:(WMFStyleManager *)styleManger {
    _styleManager = styleManger;
}

- (void)applyStyleToWindow:(UIWindow *)window {
    window.backgroundColor = [UIColor whiteColor];
    [[UIButton appearance] setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [[UIButton appearance] setBackgroundImage:[UIImage imageNamed:@"clear.png"] forState:UIControlStateNormal];
    [[UIButton appearance] setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    UIImage *backChevron = [UIImage wmf_imageFlippedForRTLLayoutDirectionNamed:@"chevron-left"];
    [[UINavigationBar appearance] setBackIndicatorImage:backChevron];
    [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:backChevron];

    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.305 green:0.305 blue:0.296 alpha:1]];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UITabBar appearance] setTranslucent:NO];

    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"clear.png"]];
    [[UITabBar appearance] setShadowImage:[UIImage imageNamed:@"tabbar-shadow"]];

    [[UITabBarItem appearance] setTitleTextAttributes:[UITabBarItem wmf_rootTabBarItemStyleForState:UIControlStateNormal]
                                             forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:[UITabBarItem wmf_rootTabBarItemStyleForState:UIControlStateSelected]
                                             forState:UIControlStateSelected];

    [[UITabBar appearance] setTintColor:[UIColor wmf_blueTintColor]];
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIToolbar class]]] setTintColor:[UIColor wmf_blueTintColor]];

    [[UISwitch appearance] setOnTintColor:[UIColor wmf_green]];
}

@end

@implementation UIViewController (WMFStyleManager)

- (WMFStyleManager *)wmf_styleManager {
    return _styleManager;
}

@end

@implementation UIView (WMFStyleManager)

- (WMFStyleManager *)wmf_styleManager {
    return _styleManager;
}

@end
