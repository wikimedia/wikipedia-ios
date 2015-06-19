//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "LangaugeSelectionDelegate.h"

@class MWKLanguageLink;
@class LanguagesViewController;

@interface LanguagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) BOOL downloadLanguagesForCurrentArticle;

@property (strong, nonatomic) IBOutlet UITableView* tableView;

// Object to receive "languageSelected:sender:" notifications.
@property (nonatomic, weak) id <LanguageSelectionDelegate> languageSelectionDelegate;

@end
