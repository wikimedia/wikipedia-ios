//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "TopMenuViewController.h"

@interface SavedPagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic) NavBarMode navBarMode;
@property (weak, nonatomic) IBOutlet UIView* emptyOverlay;

@property (weak, nonatomic) id truePresentingVC;
@property (weak, nonatomic) TopMenuViewController* topMenuViewController;

@end
