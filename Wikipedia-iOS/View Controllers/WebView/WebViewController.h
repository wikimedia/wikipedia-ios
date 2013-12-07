//
//  ViewController.h
//  Wikipedia-iOS
//
//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"

@class DiscoveryMethod, AlertLabel;

@interface WebViewController : UIViewController <UITextFieldDelegate, UIWebViewDelegate, NetworkOpDelegate, UISearchDisplayDelegate, UITableViewDelegate, UISearchBarDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *debugLabel;
@property (weak, nonatomic) IBOutlet UITableView *searchResultsTable;

@property (weak, nonatomic) IBOutlet UIView *alertView;
@property (weak, nonatomic) IBOutlet AlertLabel *alertLabel;

- (void)navigateToPage:(NSString *)pageTitle discoveryMethod:(DiscoveryMethod *)discoveryMethod;

- (IBAction)backButtonPushed:(id)sender;
- (IBAction)forwardButtonPushed:(id)sender;
- (IBAction)languageButtonPushed:(id)sender;
- (IBAction)actionButtonPushed:(id)sender;
- (IBAction)bookmarkButtonPushed:(id)sender;

@end
