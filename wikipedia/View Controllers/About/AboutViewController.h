//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "TopMenuViewController.h"

@interface AboutViewController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (nonatomic) NavBarMode navBarMode;

@property (weak, nonatomic) id truePresentingVC;
@property (weak, nonatomic) TopMenuViewController *topMenuViewController;

@end
