//  Created by Monte Hurd on 5/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ModalMenuAndContentViewController.h"

#import "TopMenuContainerView.h"
#import "MenuLabel.h"
#import "UIViewController+StatusBarHeight.h"
#import "Defines.h"
#import "TopMenuTextFieldContainer.h"
#import "TopMenuTextField.h"

@interface ModalMenuAndContentViewController ()

@property (strong, nonatomic) TopMenuViewController *topMenuViewController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topContainerHeightConstraint;

@end

@implementation ModalMenuAndContentViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString: @"TopMenuViewController_embed_in_ModalMenuAndContentViewController"]) {
		self.topMenuViewController = (TopMenuViewController *) [segue destinationViewController];
    }
}

-(void)setTopMenuText:(NSString *)topMenuText
{
    MenuLabel *label = [self.topMenuViewController getNavBarItem:NAVBAR_LABEL];
    label.text = topMenuText;
    
    TopMenuTextFieldContainer *textFieldContainer = [self.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
    textFieldContainer.textField.placeholder = topMenuText;
}

-(void)setNavBarMode:(NavBarMode)navBarMode
{
    self.topMenuViewController.navBarMode = navBarMode;
}

-(void)setNavBarStyle:(NavBarStyle)navBarStyle
{
    self.topMenuViewController.navBarStyle = navBarStyle;
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

-(void)updateViewConstraints
{
    [self constrainTopContainerHeight];
    [super updateViewConstraints];
}

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

-(void)configureContainedTopMenu
{
    self.topMenuViewController.navBarContainer.showBottomBorder = NO;
    
    MenuLabel *label = [self.topMenuViewController getNavBarItem:NAVBAR_LABEL];
    label.font = [UIFont systemFontOfSize:21];
    label.textAlignment = NSTextAlignmentCenter;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self configureContainedTopMenu];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return (self.topMenuViewController.navBarStyle == NAVBAR_STYLE_NIGHT) ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
