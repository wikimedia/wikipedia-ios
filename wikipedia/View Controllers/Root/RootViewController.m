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

@property (nonatomic) CGFloat initalCenterContainerTopConstraintConstant;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topContainerHeightConstraint;

@end

@implementation RootViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.initalCenterContainerTopConstraintConstant = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self constrainTopAndCenterContainerHeights];
}

-(void)constrainTopAndCenterContainerHeights
{
    CGFloat topMenuInitialHeight = TOP_MENU_INITIAL_HEIGHT;
    
    // iOS 7 needs to have room for a view behind the top status bar.
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        topMenuInitialHeight += [self getStatusBarHeight];
    }
    
    self.topContainerHeightConstraint.constant = topMenuInitialHeight;
    self.centerContainerTopConstraint.constant = topMenuInitialHeight;
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

-(void)updateTopMenuVisibilityConstraint
{
    // Remember the initial constants so they can be returned to when menu shown again.
    if (self.initalCenterContainerTopConstraintConstant == 0) {
        self.initalCenterContainerTopConstraintConstant = self.centerContainerTopConstraint.constant;
    }
    
    // Height for top menu when visible.
    CGFloat visibleTopMenuHeight = self.initalCenterContainerTopConstraintConstant;
    
    // iOS 7 needs to have room for a view behind the top status bar.
    CGFloat statusBarHeight = 0;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        statusBarHeight = [self getStatusBarHeight];
    }
    
    CGFloat topMenuHeight = self.topMenuHidden ? statusBarHeight : visibleTopMenuHeight;
    
    self.centerContainerTopConstraint.constant = topMenuHeight;
}

-(void)animateTopAndBottomMenuToggle
{
    // Queue it up so web view doesn't get blanked out.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        [UIView animateWithDuration:0.15f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            
            self.topMenuHidden = !self.topMenuHidden;

            WebViewController *webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];
            webVC.bottomMenuHidden = !webVC.bottomMenuHidden;
            
            [self.view setNeedsUpdateConstraints];
            //[self.view.superview layoutSubviews];
            
            [self.view.superview layoutIfNeeded];
            
        } completion:^(BOOL done){
        }];
        
    }];
}

-(void)updateViewConstraints
{
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
