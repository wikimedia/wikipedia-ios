//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "PageHistoryFetcher.h"
#import "TopMenuViewController.h"

@interface PageHistoryViewController : UIViewController <FetchFinishedDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NavBarMode navBarMode;

@property (weak, nonatomic) id truePresentingVC;
@property (weak, nonatomic) TopMenuViewController *topMenuViewController;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
