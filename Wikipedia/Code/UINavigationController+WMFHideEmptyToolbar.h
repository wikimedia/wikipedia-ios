@import UIKit;

@interface UINavigationController (WMFHideEmptyToolbar)

- (void)wmf_hideToolbarIfViewControllerHasNoToolbarItems:(UIViewController *)viewController;

@end
