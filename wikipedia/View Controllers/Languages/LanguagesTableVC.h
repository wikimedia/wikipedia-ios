//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "TopMenuViewController.h"

@interface LanguagesTableVC : UITableViewController

@property (nonatomic) BOOL downloadLanguagesForCurrentArticle;

@property (nonatomic) NavBarMode navBarMode;

@property (nonatomic, weak) id invokingVC;

@end
