//  Created by Monte Hurd on 4/18/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "TopMenuViewController.h"

@class TabularScrollView;
@interface CreditsViewController : UIViewController

@property (strong, nonatomic) IBOutlet TabularScrollView* scrollView;

@property (nonatomic) NavBarMode navBarMode;

@property (weak, nonatomic) id truePresentingVC;
@property (weak, nonatomic) TopMenuViewController* topMenuViewController;

@end
