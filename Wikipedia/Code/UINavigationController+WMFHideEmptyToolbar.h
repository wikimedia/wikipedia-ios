#import <UIKit/UIKit.h>

@interface UINavigationController (WMFHideEmptyToolbar)

- (void)wmf_hideToolbarIfViewControllerHasNoToolbarItems:(UIViewController*)viewController;

@end
