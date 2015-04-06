//  Created by Monte Hurd on 5/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ModalContentViewController.h"
#import "ModalMenuAndContentViewController.h"

@interface ModalContentViewController ()

@end

@implementation ModalContentViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    ModalMenuAndContentViewController* modalMenuAndContentVC =
        (ModalMenuAndContentViewController*)self.parentViewController;

    self.block = modalMenuAndContentVC.block;

    [self performSegueWithIdentifier:modalMenuAndContentVC.sequeIdentifier sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (self.childViewControllers.count > 0) {
        return;
    }
    [self addChildViewController:segue.destinationViewController];

    UIViewController* destVC = (UIViewController*)segue.destinationViewController;

    if (self.block) {
        self.block(destVC);
    }

    // Use the dest view controller title for the top nav label text.
    // Set in the destVC's initWithCoder.
    self.topMenuText = destVC.title;

    // Use the dest view controller navBarMode and navBarStyle top nav.
    // Set in the destVC's initWithCoder.
    [self updateTopMenuModeAndStyleForDestViewController:destVC];

    ModalMenuAndContentViewController* modalMenuAndContentVC =
        (ModalMenuAndContentViewController*)self.parentViewController;
    modalMenuAndContentVC.statusBarHidden = [destVC prefersStatusBarHidden];


    if ([destVC respondsToSelector:@selector(truePresentingVC)]) {
        [destVC performSelector:@selector(setTruePresentingVC:) withObject:modalMenuAndContentVC.truePresentingVC];
    }
    if ([destVC respondsToSelector:@selector(topMenuViewController)]) {
        [destVC performSelector:@selector(setTopMenuViewController:) withObject:modalMenuAndContentVC.topMenuViewController];
    }

    UIView* view = destVC.view;

    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.frame            = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:view];
    [segue.destinationViewController didMoveToParentViewController:self];
}

- (void)updateTopMenuModeAndStyleForDestViewController:(UIViewController*)destVC {
    SEL selector = NSSelectorFromString(@"navBarMode");
    if ([destVC respondsToSelector:selector]) {
        NSInvocation* invocation =
            [NSInvocation invocationWithMethodSignature:[[destVC class] instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:destVC];
        [invocation invoke];
        NSUInteger destNavBarMode;
        [invocation getReturnValue:&destNavBarMode];
        self.navBarMode = (NavBarMode)destNavBarMode;
    }

    selector = NSSelectorFromString(@"navBarStyle");
    if ([destVC respondsToSelector:selector]) {
        NSInvocation* invocation =
            [NSInvocation invocationWithMethodSignature:[[destVC class] instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:destVC];
        [invocation invoke];
        NSUInteger destNavBarStyle;
        [invocation getReturnValue:&destNavBarStyle];
        self.navBarStyle = (NavBarStyle)destNavBarStyle;
    }
}

- (void)setTopMenuText:(NSString*)topMenuText {
    ModalMenuAndContentViewController* modalMenuAndContentVC =
        (ModalMenuAndContentViewController*)self.parentViewController;
    modalMenuAndContentVC.topMenuText = topMenuText;
}

- (void)setNavBarMode:(NavBarMode)navBarMode {
    ModalMenuAndContentViewController* modalMenuAndContentVC =
        (ModalMenuAndContentViewController*)self.parentViewController;
    modalMenuAndContentVC.navBarMode = navBarMode;
}

- (void)setNavBarStyle:(NavBarStyle)navBarStyle {
    ModalMenuAndContentViewController* modalMenuAndContentVC =
        (ModalMenuAndContentViewController*)self.parentViewController;
    modalMenuAndContentVC.navBarStyle = navBarStyle;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
