//
//  ViewController.h
//  Wikipedia-iOS
//
//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITextFieldDelegate, UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
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
- (IBAction)menuButtonPushed:(id)sender;

@end
