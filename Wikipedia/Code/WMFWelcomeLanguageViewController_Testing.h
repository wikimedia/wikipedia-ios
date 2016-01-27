//
//  WMFWelcomeLanguageViewController_Testing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/26/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFWelcomeLanguageViewController.h"
#import "LanguagesViewController.h"
#import "MWKLanguageLinkController.h"

@interface WMFWelcomeLanguageViewController ()
<LanguageSelectionDelegate>

@property (strong, nonatomic) IBOutlet UITableView* languageTableView;

@end
