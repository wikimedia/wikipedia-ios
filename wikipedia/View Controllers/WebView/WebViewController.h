//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"
#import "CenterNavController.h"

@interface WebViewController : UIViewController <UIWebViewDelegate, NetworkOpDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic) BOOL bottomMenuHidden;

// Reloads the current article from the core data cache.
// If "invalidateCache" is set to YES the article will be re-downloaded first.
-(void)reloadCurrentArticleInvalidatingCache:(BOOL)invalidateCache;

// If "invalidateCache" is set to YES the article will be re-downloaded first.
-(void)navigateToPage: (NSString *)title
               domain: (NSString *)domain
      discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod
    invalidatingCache: (BOOL)invalidateCache;

-(void)tocScrollWebViewToPoint: (CGPoint)point
                      duration: (CGFloat)duration
                   thenHideTOC: (BOOL)hideTOC;

-(void)tocHide;
-(void)tocToggle;
-(void)saveWebViewScrollOffset;

@end
