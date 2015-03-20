//  Created by Monte Hurd on 5/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class TopMenuViewController, BottomMenuViewController, CenterNavController;

@interface RootViewController : UIViewController

@property (weak, nonatomic) TopMenuViewController* topMenuViewController;
@property (weak, nonatomic) CenterNavController* centerNavController;

@property (nonatomic) BOOL topMenuHidden;
@property (nonatomic) BOOL shouldShowSplashOnAppear;
@property (nonatomic) BOOL isAnimatingTopAndBottomMenuHidden;

- (void)animateTopAndBottomMenuHidden:(BOOL)hidden;

- (void)togglePrimaryMenu;

- (void)pushViewController:(UIViewController*)viewController animated:(BOOL)animated;
- (UIViewController*)popViewControllerAnimated:(BOOL)animated;
- (void)popToViewController:(UIViewController*)viewController animated:(BOOL)animated;
- (void)popToRootViewControllerAnimated:(BOOL)animated;

- (BOOL)shouldHideTopNavIfNecessaryForViewController:(UIViewController*)vc;

@end
