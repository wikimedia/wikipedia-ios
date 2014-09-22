//  Created by Monte Hurd on 5/22/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "TopMenuViewController.h"
#import "FetcherBase.h"

@interface PrimaryMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NavBarMode navBarMode;
@property (nonatomic) NavBarStyle navBarStyle;

@property (weak, nonatomic) id truePresentingVC;
@property (weak, nonatomic) TopMenuViewController *topMenuViewController;

@end
