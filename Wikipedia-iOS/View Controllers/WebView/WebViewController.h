//
//  ViewController.h
//  Wikipedia-iOS
//
//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"
#import "NavController.h"

@interface WebViewController : UIViewController <UIWebViewDelegate, NetworkOpDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

-(void)tocToggle;
-(void)saveWebViewScrollOffset;

-(void)reloadCurrentArticle;
-(void)reloadCurrentArticleInvalidatingCache;

-(void)navigateToPage:(NSString *)title domain:(NSString *)domain discoveryMethod:(ArticleDiscoveryMethod)discoveryMethod;

@end
