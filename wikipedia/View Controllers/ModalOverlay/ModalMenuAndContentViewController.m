//  Created by Monte Hurd on 5/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ModalMenuAndContentViewController.h"

#import "TopMenuContainerView.h"
#import "MenuLabel.h"
#import "UIViewController+StatusBarHeight.h"
#import "Defines.h"
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
    
    TopMenuTextField *textField = [self.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
    textField.placeholder = topMenuText;
}

-(void)setNavBarMode:(NavBarMode)navBarMode
{
    self.topMenuViewController.navBarMode = navBarMode;
}

-(void)setNavBarStyle:(NavBarStyle)navBarStyle
{
    self.topMenuViewController.navBarStyle = navBarStyle;
}

-(void)configureContainedTopMenu
{
    self.topMenuViewController.navBarContainer.showBottomBorder = NO;
    
    MenuLabel *label = [self.topMenuViewController getNavBarItem:NAVBAR_LABEL];
    label.font = [UIFont systemFontOfSize:21];
    label.textAlignment = NSTextAlignmentCenter;

    CGFloat topMenuInitialHeight = TOP_MENU_INITIAL_HEIGHT;
    
    // iOS 7 needs to have room for a view behind the top status bar.
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        topMenuInitialHeight += [self getStatusBarHeight];
    }
    
    self.topContainerHeightConstraint.constant = topMenuInitialHeight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self configureContainedTopMenu];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        switch (self.topMenuViewController.navBarStyle) {
            case NAVBAR_STYLE_NIGHT:
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
                break;
                
            default:
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
                break;
        }
    }

}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
