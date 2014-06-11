//  Created by Monte Hurd on 5/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "BottomMenuViewController.h"
#import "WebViewController.h"

#import "UINavigationController+SearchNavStack.h"
#import "TopMenuContainerView.h"
#import "UIViewController+StatusBarHeight.h"

#import "Defines.h"

#import "ModalMenuAndContentViewController.h"

#import "UIViewController+PresentModal.h"

@interface RootViewController (){
    
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerContainerTopConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topContainerHeightConstraint;

@end

@implementation RootViewController

-(void)constrainTopContainerHeight
{
    CGFloat topMenuHeight = TOP_MENU_INITIAL_HEIGHT;
    
    // iOS 7 needs to have room for a view behind the top status bar.
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        if(!self.statusBarHidden){
            topMenuHeight += [self getStatusBarHeight];
        }
    }

    self.topContainerHeightConstraint.constant = topMenuHeight;
}

-(void)setTopMenuHidden:(BOOL)topMenuHidden
{
    if (self.topMenuHidden == topMenuHidden) return;

    _topMenuHidden = topMenuHidden;

    // Fade out the top menu when it is hidden.
    CGFloat alpha = topMenuHidden ? 0.0 : 1.0;
    
    //self.topMenuViewController.navBarContainer.alpha = alpha;
    for (UIView *v in self.topMenuViewController.navBarContainer.subviews) {
        v.alpha = alpha;
    }
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return (self.topMenuViewController.navBarStyle == NAVBAR_STYLE_NIGHT) ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.statusBarHidden = [self.centerNavController.topViewController prefersStatusBarHidden];
}

-(void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    
    self.topMenuViewController.statusBarHidden = statusBarHidden;
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
    [self.view setNeedsUpdateConstraints];
}

-(void)updateTopMenuVisibilityConstraint
{
    // Hides the top menu by raising the center container's top - since the top menu sits on
    // top of the center container the top menue gets pushed up offscreen. Shows the top menu
    // by lowering the center container.

    CGFloat topMenuVisibleHeight = TOP_MENU_INITIAL_HEIGHT;
    CGFloat statusBarHeight = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? [self getStatusBarHeight] : 0;
    
    if (self.statusBarHidden) statusBarHeight = 0;
    
    CGFloat topMenuHeight = self.topMenuHidden ? statusBarHeight : (topMenuVisibleHeight + statusBarHeight);
    
    self.centerContainerTopConstraint.constant = topMenuHeight;
}

-(void)animateTopAndBottomMenuToggle
{
    // Queue it up so web view doesn't get blanked out.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        [UIView animateWithDuration:0.15f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            
            self.topMenuHidden = !self.topMenuHidden;

            WebViewController *webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];
            webVC.bottomMenuHidden = self.topMenuHidden;
            
            [self.view setNeedsUpdateConstraints];
            //[self.view.superview layoutSubviews];
            
            [self.view.superview layoutIfNeeded];
            
        } completion:^(BOOL done){
        }];
        
    }];
}

-(void)updateViewConstraints
{
    [self constrainTopContainerHeight];

    [self updateTopMenuVisibilityConstraint];

    [super updateViewConstraints];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString: @"TopMenuViewController_embed"]) {
		self.topMenuViewController = (TopMenuViewController *) [segue destinationViewController];
	}else if ([segue.identifier isEqualToString: @"CenterNavController_embed"]) {
		self.centerNavController = (CenterNavController *) [segue destinationViewController];
    }
}

-(void)updateTopMenuVisibilityForViewController:(UIViewController *)viewController
{
    if(![viewController isMemberOfClass:[WebViewController class]]){
        // Ensure the top menu is shown after navigating away from the web view.
        
        self.topMenuHidden = NO;
        
        [self.view setNeedsUpdateConstraints];
        
        [self.view.superview layoutIfNeeded];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)togglePrimaryMenu
{
    if (
        self.presentedViewController.isBeingPresented
        ||
        self.presentedViewController.isBeingDismissed
        )
    {
        return;
    }

    if ([self.presentedViewController isMemberOfClass:[ModalMenuAndContentViewController class]]) {
        [self dismissViewControllerAnimated:YES completion:^{}];
    }else{
        [self performModalSequeWithID: @"modal_segue_show_primary_menu"
                      transitionStyle: UIModalTransitionStyleCrossDissolve
                                block: nil];
    }
}

@end
