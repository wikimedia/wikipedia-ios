#import "WMFNavigationController.h"

@interface WMFNavigationController ()

@end

@implementation WMFNavigationController

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.visibleViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.visibleViewController;
}

@end
