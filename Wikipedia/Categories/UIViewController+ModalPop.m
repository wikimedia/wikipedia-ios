//  Created by Monte Hurd on 6/26/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+ModalPop.h"
#import "ModalMenuAndContentViewController.h"

@implementation UIViewController (ModalPop)

- (void)popModal {
    // Hide this view controller.
    if (!(self.isBeingPresented || self.isBeingDismissed)) {
        //[self.truePresentingVC dismissViewControllerAnimated:YES completion:^{}];
        id presentingVC = nil;
        SEL selector    = @selector(truePresentingVC);
        if ([self respondsToSelector:selector]) {
            IMP imp = [self methodForSelector:selector];
            id (* func)(id, SEL) = (void*)imp;
            presentingVC = func(self, selector);
        }
        [presentingVC dismissViewControllerAnimated:YES completion:^{}];
        //[self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }
}

- (void)popModalToRoot {
    // Hide the black menu which presented this view controller.

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        // Workaround for messed up transitions on iOS 8 beta 5...
        // For some reason contrary to documentation it's animating the lowest VC
        // instead of the topmost VC? MADNESS! Filed with Apple as bug 18235825.
        [self addSnapshotToModalFromRoot];
    }

    [ROOT dismissViewControllerAnimated:YES completion:nil];
}

- (void)addSnapshotToModalFromRoot {
    UIViewController* bottommost = ROOT.presentedViewController;
    UIViewController* topmost    = bottommost;
    while (topmost && topmost.presentedViewController) {
        topmost = topmost.presentedViewController;
    }

    if (topmost != bottommost) {
        // Take a snapshot view of the topmost view controller's view...
        UIView* snapshot = [topmost.view snapshotViewAfterScreenUpdates:NO];

        // Put it in the bottommost view controller on top of whatever's already there.
        // It'll vanish when the view is destroyed, so no need to clean up manually.
        [bottommost.view addSubview:snapshot];

        // Also copy the transition style!
        bottommost.modalTransitionStyle = topmost.modalTransitionStyle;
    }
}

@end
