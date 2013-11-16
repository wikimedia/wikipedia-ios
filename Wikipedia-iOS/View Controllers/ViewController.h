//
//  ViewController.h
//  Wikipedia-iOS
//
//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"

@interface ViewController : UIViewController <UITextFieldDelegate, UIWebViewDelegate, NetworkOpDelegate, UISearchDisplayDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *languageButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bookmarksButton;

- (IBAction)backButtonPushed:(id)sender;
- (IBAction)forwardButtonPushed:(id)sender;
- (IBAction)languageButtonPushed:(id)sender;
- (IBAction)actionButtonPushed:(id)sender;
- (IBAction)bookmarkButtonPushed:(id)sender;

@end

/*

To do:
x    make image result cell use a reusable cell
x    make search result thumb images use dependent async op
x    track down crash
     rolling search timeout
x    placeholder image when none found
         bundle in app
     query for further results when bottom of results scrolled to!
     add small part of description to search result
         will need another query? or one per title?
*/