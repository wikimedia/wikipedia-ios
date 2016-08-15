#import "WMFRotationRespectingNavigationController.h"

@implementation WMFRotationRespectingNavigationController

- (BOOL)shouldAutorotate {
    if (self.presentedViewController && ![self.presentedViewController isKindOfClass:[UIAlertController class]]) {
        return self.presentedViewController.shouldAutorotate;
    } else if (self.topViewController) {
        return self.topViewController.shouldAutorotate;
    } else {
        return YES;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.presentedViewController && ![self.presentedViewController isKindOfClass:[UIAlertController class]]) {
        return self.presentedViewController.supportedInterfaceOrientations;
    } else if (self.topViewController) {
        return self.topViewController.supportedInterfaceOrientations;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (self.presentedViewController && ![self.presentedViewController isKindOfClass:[UIAlertController class]]) {
        return self.presentedViewController.preferredInterfaceOrientationForPresentation;
    } else if (self.topViewController) {
        return self.topViewController.preferredInterfaceOrientationForPresentation;
    } else {
        return UIInterfaceOrientationPortrait;
    }
}

@end