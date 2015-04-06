//  Created by Monte Hurd on 12/18/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "TopMenuViewController.h"

@interface SecondaryMenuViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic) NavBarMode navBarMode;

@property (weak, nonatomic) id truePresentingVC;

@end
