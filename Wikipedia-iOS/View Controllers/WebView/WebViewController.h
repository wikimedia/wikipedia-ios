//
//  ViewController.h
//  Wikipedia-iOS
//
//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"

@class DiscoveryMethod;

@interface WebViewController : UIViewController <UIWebViewDelegate, NetworkOpDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (weak, nonatomic) IBOutlet UIView *bottomBarView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBarViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBarViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UIButton *tocButton;
@property (weak, nonatomic) IBOutlet UIButton *langButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewRightConstraint;

-(void)tocToggle;
-(void)saveWebViewScrollOffset;
-(void)reloadCurrentArticle;
-(void)showLanguages;

- (IBAction)tocButtonPushed:(id)sender;
- (IBAction)backButtonPushed:(id)sender;
- (IBAction)forwardButtonPushed:(id)sender;
- (IBAction)languageButtonPushed:(id)sender;
- (IBAction)actionButtonPushed:(id)sender;
- (IBAction)bookmarkButtonPushed:(id)sender;

@end
