#import "WMFRotationRespectingNavigationController.h"

@implementation WMFRotationRespectingNavigationController

- (BOOL)shouldAutorotate {
    if (self.presentedViewController) {
        return self.presentedViewController.shouldAutorotate;
    } else if (self.topViewController) {
        return self.topViewController.shouldAutorotate;
    } else {
        return [super shouldAutorotate];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.presentedViewController) {
        return self.presentedViewController.supportedInterfaceOrientations;
    } else if (self.topViewController) {
        return self.topViewController.supportedInterfaceOrientations;
    } else {
        return [super supportedInterfaceOrientations];
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (self.presentedViewController) {
        return self.presentedViewController.preferredInterfaceOrientationForPresentation;
    } else if (self.topViewController) {
        return self.topViewController.preferredInterfaceOrientationForPresentation;
    } else {
        return [super preferredInterfaceOrientationForPresentation];
    }
}

@end
