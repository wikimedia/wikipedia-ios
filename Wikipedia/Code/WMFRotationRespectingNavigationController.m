#import "WMFRotationRespectingNavigationController.h"

@implementation WMFRotationRespectingNavigationController

- (BOOL)shouldAutorotate {
    UIViewController* vcToRespect = self.presentedViewController ? self.presentedViewController : self.topViewController;
    if (vcToRespect && [vcToRespect isKindOfClass:[UIAlertController class]]) {
        return [vcToRespect shouldAutorotate];
    } else {
        return [super shouldAutorotate];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIViewController* vcToRespect = self.presentedViewController ? self.presentedViewController : self.topViewController;
    if (vcToRespect && [vcToRespect isKindOfClass:[UIAlertController class]]) {
        return [vcToRespect supportedInterfaceOrientations];
    } else {
        return [super supportedInterfaceOrientations];
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    UIViewController* vcToRespect = self.presentedViewController ? self.presentedViewController : self.topViewController;
    if (vcToRespect && [vcToRespect isKindOfClass:[UIAlertController class]]) {
        return [vcToRespect preferredInterfaceOrientationForPresentation];
    } else {
        return [super preferredInterfaceOrientationForPresentation];
    }
}

@end