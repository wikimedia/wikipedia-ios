#import "WMFTabBarController.h"
#import "Wikipedia-Swift.h"

@interface WMFTabBarController ()

@property (strong, nonatomic) WMFTheme *theme;

@end

@implementation WMFTabBarController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.selectedViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.selectedViewController;
}

- (void)didReceiveMemoryWarning {
    NSArray<UIView*> *badgeSuperviews = [self.tabBar wmf_badgeSuperviews];

    UIView *badgeSuperview = badgeSuperviews[2]; // 2 is hardcoded to the "Saved" button index

    BadgeDotView *badgeDotView = [[BadgeDotView alloc] init];
    [badgeDotView applyTheme: self.theme];
    
    [badgeSuperview addSubview:badgeDotView];
    badgeDotView.frame = CGRectMake(10, -8, 16, 16);
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;

// TODO: would need to re-apply theme to BadgeDotView's here.

}

@end
