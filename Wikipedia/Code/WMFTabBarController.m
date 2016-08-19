#import "WMFTabBarController.h"

@interface WMFTabBarController ()

@end

@implementation WMFTabBarController

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.selectedViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.selectedViewController;
}

@end
