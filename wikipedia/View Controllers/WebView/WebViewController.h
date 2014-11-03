//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "CenterNavController.h"
#import "PullToRefreshViewController.h"
#import "Article.h"
#import "ArticleFetcher.h"

@class BottomMenuViewController;

@interface WebViewController : PullToRefreshViewController <UIWebViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, FetchFinishedDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic) BOOL bottomMenuHidden;
@property (nonatomic) BOOL referencesHidden;
@property (nonatomic) BOOL scrollingToTop;

@property (weak, nonatomic) BottomMenuViewController *bottomMenuViewController;

-(void)referencesShow:(NSDictionary *)payload;
-(void)referencesHide;

// Reloads the current article from the core data cache.
// If "invalidateCache" is set to YES the article will be re-downloaded first.
-(void)reloadCurrentArticleInvalidatingCache:(BOOL)invalidateCache;

// If "invalidateCache" is set to YES the article will be re-downloaded first.
-(void)navigateToPage: (MWKTitle *)title
      discoveryMethod: (MWKHistoryDiscoveryMethod)discoveryMethod
    invalidatingCache: (BOOL)invalidateCache
 showLoadingIndicator: (BOOL)showLoadingIndicator;

-(void)tocScrollWebViewToSectionWithElementId: (NSString *)elementId
                                     duration: (CGFloat)duration
                                  thenHideTOC: (BOOL)hideTOC;

-(void)tocHide;
-(void)tocToggle;
-(void)saveWebViewScrollOffset;

@end
