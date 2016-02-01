#import "UINavigationController+WMFHideEmptyToolbar.h"

@implementation UINavigationController (WMFHideEmptyToolbar)

- (void)wmf_hideToolbarIfViewControllerHasNoToolbarItems:(UIViewController*)viewController; {
    BOOL isToolbarEmpty = [viewController toolbarItems].count == 0;
    [self setToolbarHidden:isToolbarEmpty];
}

@end
