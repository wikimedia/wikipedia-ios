//  Created by Monte Hurd on 5/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "TopMenuViewController.h"

@interface ModalContentViewController : UIViewController

@property (strong, nonatomic) NSString* topMenuText;
@property (nonatomic) NavBarMode navBarMode;
@property (nonatomic) NavBarStyle navBarStyle;

@property (nonatomic, copy) void (^ block)(id);

@end
