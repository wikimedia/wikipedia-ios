//  Created by Monte Hurd on 5/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "TopMenuViewController.h"

@interface ModalMenuAndContentViewController : UIViewController

@property (strong, nonatomic) NSString* sequeIdentifier;
@property (strong, nonatomic) NSString* topMenuText;

@property (nonatomic) NavBarMode navBarMode;
@property (nonatomic) NavBarStyle navBarStyle;

@property (nonatomic) BOOL statusBarHidden;

@property (nonatomic, copy) void (^ block)(id);

@property (strong, nonatomic) TopMenuViewController* topMenuViewController;

@property (weak, nonatomic) id truePresentingVC;

@end
