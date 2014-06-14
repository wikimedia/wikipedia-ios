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

@property (strong, nonatomic) UIViewController *topVC;

@end

@implementation RootViewController

-(void)constrainTopContainerHeight
{
    CGFloat topMenuHeight = TOP_MENU_INITIAL_HEIGHT;
    
    // iOS 7 needs to have room for a view behind the top status bar.
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        if(!self.topVC.prefersStatusBarHidden){
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
    
    [self.view setNeedsUpdateConstraints];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return (self.topMenuViewController.navBarStyle == NAVBAR_STYLE_NIGHT) ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.topVC;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.topVC;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self animateStatusBarHeightChangesForViewController:viewController then:^{
        [self.centerNavController pushViewController:viewController animated:animated];
    }];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    NSInteger index = self.centerNavController.viewControllers.count - 2;
    if (index < 0) return nil;
    id vcBeneath = self.centerNavController.viewControllers[index];
    
    [self animateStatusBarHeightChangesForViewController:vcBeneath then:^{
        [self.centerNavController popViewControllerAnimated:animated];
    }];
    return vcBeneath;
}

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self animateStatusBarHeightChangesForViewController:viewController then:^{
        [self.centerNavController popToViewController:viewController animated:animated];
    }];
}

-(void)animateStatusBarHeightChangesForViewController: (UIViewController *)vc
                                                 then: (void (^)(void))block
{
    // Animates changes to the top menu to adjust room for the status bar based on the
    // wishes of the view controller being presented.
    CGFloat duration = 0.1;
    
    self.topVC = vc;
    
    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{

        if(![self.topVC isMemberOfClass:[WebViewController class]]){
            // Ensure the top menu is shown when navigating away from the web view
            // (in case when the web view was onscreen the user toggled the chrome to
            // be hidden).
            if(self.topMenuHidden) {
                self.topMenuHidden = NO;
            }
        }

        // Allow the top menu to adjust its views' heights based on whether the
        // top view controller wants the status bar shown or not.
        self.topMenuViewController.statusBarHidden = self.topVC.prefersStatusBarHidden;
        
        [self.view setNeedsUpdateConstraints];
        
        // Update status bar according to topVC's wishes.
        if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
            [self setNeedsStatusBarAppearanceUpdate];
        }
        
        [self.view layoutIfNeeded];
    } completion:^(BOOL done){
        block();
    }];
}

-(void)updateTopMenuVisibilityConstraint
{
    // Hides the top menu by raising the center container's top - since the top menu sits on
    // top of the center container the top menue gets pushed up offscreen. Shows the top menu
    // by lowering the center container.

    CGFloat topMenuVisibleHeight = TOP_MENU_INITIAL_HEIGHT;
    CGFloat statusBarHeight = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? [self getStatusBarHeight] : 0;
    
    if (self.topVC.prefersStatusBarHidden) statusBarHeight = 0;
    
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
            
            [webVC.view setNeedsUpdateConstraints];
            
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
