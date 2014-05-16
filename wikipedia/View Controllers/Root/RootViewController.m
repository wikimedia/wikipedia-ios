//  Created by Monte Hurd on 5/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "BottomMenuViewController.h"

@interface RootViewController (){
    
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerContainerTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerContainerBottomConstraint;

@property (nonatomic) CGFloat initalCenterContainerTopConstraintConstant;
@property (nonatomic) CGFloat initalCenterContainerBottomConstraintConstant;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomContainerHeightConstraint;

@end

@implementation RootViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.initalCenterContainerTopConstraintConstant = 0;
        self.initalCenterContainerBottomConstraintConstant = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGFloat topMenuInitialHeight = 45;
    CGFloat bottomMenuInitialHeight = 0;
    
    // iOS 7 needs to have room for a view behind the top status bar.
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        topMenuInitialHeight += [self getStatusBarHeight];
    }
    
    self.centerContainerTopConstraint.constant = topMenuInitialHeight;
    self.topContainerHeightConstraint.constant = topMenuInitialHeight;
    
    self.centerContainerBottomConstraint.constant = bottomMenuInitialHeight;
    self.bottomContainerHeightConstraint.constant = bottomMenuInitialHeight;
}

-(void)setHideTopAndBottomMenus:(BOOL)hideTopAndBottomMenus
{
    _hideTopAndBottomMenus = hideTopAndBottomMenus;

    // iOS 6 can blank out the web view this isn't scheduled for next run loop.
    [[NSRunLoop currentRunLoop] performSelector: @selector(updateMenuVisibility)
                                         target: self
                                       argument: nil
                                          order: 0
                                          modes: [NSArray arrayWithObject:@"NSDefaultRunLoopMode"]];
}

-(void)updateMenuVisibility
{
    // Remember the initial constants so they can be returned to when menus are shown again.
    if (self.initalCenterContainerTopConstraintConstant == 0) {
        self.initalCenterContainerTopConstraintConstant = self.centerContainerTopConstraint.constant;
    }
    if (self.initalCenterContainerBottomConstraintConstant == 0) {
        self.initalCenterContainerBottomConstraintConstant = self.centerContainerBottomConstraint.constant;
    }
    
    // Fade out the top menu when it is hidden.
    CGFloat alpha = self.hideTopAndBottomMenus ? 0.0 : 1.0;
    
    // Height for top and bottom menus when visible.
    CGFloat visibleTopMenuHeight = self.initalCenterContainerTopConstraintConstant;
    CGFloat visibleBottomMenuHeight = self.initalCenterContainerBottomConstraintConstant;
    
    // iOS 7 needs to have room for a view behind the top status bar.
    CGFloat statusBarHeight = 0;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        statusBarHeight = [self getStatusBarHeight];
    }
    
    CGFloat topMenuHeight = self.hideTopAndBottomMenus ? statusBarHeight : visibleTopMenuHeight;
    CGFloat bottomMenuHeight = self.hideTopAndBottomMenus ? 0 : visibleBottomMenuHeight;
    
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        
        self.centerContainerTopConstraint.constant = topMenuHeight;
        self.centerContainerBottomConstraint.constant = bottomMenuHeight;
        
        self.topMenuViewController.view.alpha = alpha;
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL done){
        
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString: @"TopMenuViewController_embed"]) {
		self.topMenuViewController = (TopMenuViewController *) [segue destinationViewController];
	}else if ([segue.identifier isEqualToString: @"BottomMenuViewController_embed"]) {
		self.bottomMenuViewController = (BottomMenuViewController *) [segue destinationViewController];
	}else if ([segue.identifier isEqualToString: @"CenterNavController_embed"]) {
		self.centerNavController = (CenterNavController *) [segue destinationViewController];
    }
}

-(CGFloat)getStatusBarHeight
{
    return 20;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    //self.hideTopAndBottomMenus = !self.hideTopAndBottomMenus;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
