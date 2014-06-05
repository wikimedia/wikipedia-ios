//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"
#import "TopMenuViewController.h"

@interface PageHistoryViewController : UITableViewController <NetworkOpDelegate>

@property (nonatomic) NavBarMode navBarMode;

@end
