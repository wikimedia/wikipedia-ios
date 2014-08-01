//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"
#import "CenterNavController.h"
#import "MWPageTitle.h"
#import "PullToRefreshViewController.h"

@interface WebViewController : PullToRefreshViewController <UIWebViewDelegate, NetworkOpDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic) BOOL bottomMenuHidden;
@property (nonatomic) BOOL referencesHidden;

-(void)referencesShow:(NSDictionary *)payload;
-(void)referencesHide;

// Reloads the current article from the core data cache.
// If "invalidateCache" is set to YES the article will be re-downloaded first.
-(void)reloadCurrentArticleInvalidatingCache:(BOOL)invalidateCache;

// If "invalidateCache" is set to YES the article will be re-downloaded first.
-(void)navigateToPage: (MWPageTitle *)title
               domain: (NSString *)domain
      discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod
    invalidatingCache: (BOOL)invalidateCache;

-(void)tocScrollWebViewToSectionWithElementId: (NSString *)elementId
                                     duration: (CGFloat)duration
                                  thenHideTOC: (BOOL)hideTOC;

-(void)tocHide;
-(void)tocToggle;
-(void)saveWebViewScrollOffset;

@end
