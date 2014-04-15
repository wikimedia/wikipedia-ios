//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewController.h"

#import "WikipediaAppUtils.h"
#import "DownloadWikipediaZeroMessageOp.h"
#import "ArticleDataContextSingleton.h"
#import "SectionEditorViewController.h"
#import "DownloadNonLeadSectionsOp.h"
#import "ArticleCoreDataObjects.h"
#import "DownloadLeadSectionOp.h"
#import "CommunicationBridge.h"
#import "TOCViewController.h"
#import "LanguagesTableVC.h"
#import "SessionSingleton.h"
#import "QueuesSingleton.h"
#import "NavBarTextField.h"
#import "MWLanguageInfo.h"
#import "NavController.h"
#import "Defines.h"

#import "UIViewController+SearchChildViewControllers.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "UIScrollView+NoHorizontalScrolling.h"
#import "UIViewController+HideKeyboard.h"
#import "UIWebView+HideScrollGradient.h"
#import "UIWebView+ElementLocation.h"
#import "UIViewController+LogEvent.h"
#import "UIView+RemoveConstraints.h"
#import "UIViewController+Alert.h"
#import "Section+ImageRecords.h"
#import "NSString+Extras.h"

//#import "UIView+Debugging.h"

#define TOC_TOGGLE_ANIMATION_DURATION 0.3f
#define NAV ((NavController *)self.navigationController)

typedef enum {
    DISPLAY_LEAD_SECTION = 0,
    DISPLAY_APPEND_NON_LEAD_SECTIONS = 1,
    DISPLAY_ALL_SECTIONS = 2
} DisplayMode;

@interface WebViewController (){

}

@property (strong, nonatomic) CommunicationBridge *bridge;

@property (nonatomic) CGPoint scrollOffset;

@property (nonatomic) BOOL unsafeToScroll;

@property (nonatomic) NSInteger indexOfFirstOnscreenSectionBeforeRotate;
@property (nonatomic) NSUInteger sectionToEditIndex;

@property (strong, nonatomic) NSDictionary *adjacentHistoryIDs;
@property (strong, nonatomic) NSString *externalUrl;

@property (weak, nonatomic) IBOutlet UIView *bottomBarView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UIButton *tocButton;
@property (weak, nonatomic) IBOutlet UIButton *langButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewRightConstraint;

@property (weak, nonatomic) NSLayoutConstraint *pullToRefreshViewBottomConstraint;
@property (strong, nonatomic) UILabel *pullToRefreshLabel;
@property (strong, nonatomic) UIView *pullToRefreshView;

@property (strong, nonatomic) TOCViewController *tocVC;
@property (strong, nonatomic) UISwipeGestureRecognizer *tocSwipeLeftRecognizer;
@property (strong, nonatomic) UISwipeGestureRecognizer *tocSwipeRightRecognizer;

- (IBAction)tocButtonPushed:(id)sender;
- (IBAction)backButtonPushed:(id)sender;
- (IBAction)forwardButtonPushed:(id)sender;
- (IBAction)languageButtonPushed:(id)sender;

@end

#pragma mark Internal variables

@implementation WebViewController {
    CGFloat scrollViewDragBeganVerticalOffset_;
    ArticleDataContextSingleton *articleDataContext_;
}

#pragma mark View lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.sectionToEditIndex = 0;

    self.forwardButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.indexOfFirstOnscreenSectionBeforeRotate = -1;

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(webViewFinishedLoading)
                                                 name: @"WebViewFinishedLoading"
                                               object: nil];
    
    self.unsafeToScroll = NO;
    self.scrollOffset = CGPointZero;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(saveCurrentPage)
                                                 name: @"SavePage"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(searchFieldBecameFirstResponder)
                                                 name: @"SearchFieldBecameFirstResponder"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(zeroStateChanged:)
                                                 name: @"ZeroStateChanged"
                                               object: nil];

    [self showAlert:@""];

    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
    
    scrollViewDragBeganVerticalOffset_ = 0.0f;
    
    // Ensure web view can appear beneath translucent nav bar when scrolled up
    for (UIView *subview in self.webView.subviews) {
        subview.clipsToBounds = NO;
    }

    // Ensure the keyboard hides if the web view is scrolled
    self.webView.scrollView.delegate = self;

    self.webView.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1.0];

    [self.webView hideScrollGradient];

    [self reloadCurrentArticle];
    
    [self setupPullToRefresh];
    
    // Restrict the web view from scrolling horizonally.
    [self.webView.scrollView addObserver: self
                              forKeyPath: @"contentSize"
                                 options: NSKeyValueObservingOptionNew
                                 context: nil];
    
    [self tocSetupSwipeGestureRecognizers];
    
    // UIWebView has a bug which causes a black bar to appear at
    // bottom of the web view if toc quickly dragged on and offscreen.
    self.webView.opaque = NO;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //[self.view randomlyColorSubviews];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NAV.navBarMode = NAVBAR_MODE_SEARCH;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self tocHide];
    [super viewWillDisappear:animated];
}

#pragma mark Edit section

-(void)showSectionEditor
{
    [self logEvent: @{@"action": @"start"}
            schema: LOG_SCHEMA_EDIT];

    SectionEditorViewController *sectionEditVC =
    [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"SectionEditorViewController"];

    NSManagedObjectID *articleID =
    [articleDataContext_.mainContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                   domain: [SessionSingleton sharedInstance].currentArticleDomain];
    if (articleID) {
        Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
        
        Section *section =
        (Section *)[articleDataContext_.mainContext getEntityForName: @"Section"
                                                 withPredicateFormat: @"article == %@ AND index == %@", article, @(self.sectionToEditIndex)];
        
        sectionEditVC.sectionID = section.objectID;
    }
    
    [self.navigationController pushViewController: sectionEditVC
                                         animated: YES];
}

-(void)searchFieldBecameFirstResponder
{
    [self tocHide];
}

#pragma mark Update constraints

-(void)updateViewConstraints
{
    [super updateViewConstraints];
    
    [self tocConstrainView];
}

#pragma mark Languages

-(void)showLanguages
{
    LanguagesTableVC *languagesTableVC =
        [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"LanguagesTableVC"];

    languagesTableVC.downloadLanguagesForCurrentArticle = YES;
    
    CATransition *transition = [languagesTableVC getTransition];
    
    languagesTableVC.selectionBlock = ^(NSDictionary *selectedLangInfo){
    
        [self.navigationController.view.layer addAnimation:transition forKey:nil];
        // Don't animate - so the transistion set above will be used.
        [NAV loadArticleWithTitle: selectedLangInfo[@"*"]
                           domain: selectedLangInfo[@"code"]
                         animated: NO
                  discoveryMethod: DISCOVERY_METHOD_SEARCH];
    };
    
    [self.navigationController.view.layer addAnimation:transition forKey:nil];

    // Don't animate - so the transistion set above will be used.
    [self.navigationController pushViewController:languagesTableVC animated:NO];
}

#pragma mark Angle from velocity vector

-(CGFloat)getAngleInDegreesForVelocity:(CGPoint)velocity
{
    // Returns angle from 0 to 360 (ccw from right)
    return (atan2(velocity.y, -velocity.x) / M_PI * 180 + 180);
}

-(CGFloat)getAbsoluteHorizontalDegreesFromVelocity:(CGPoint)velocity
{
    // Returns deviation from horizontal axis in degrees.
    return (atan2(fabs(velocity.y), fabs(velocity.x)) / M_PI * 180);
}

#pragma mark Table of contents

-(BOOL)tocDrawerIsOpen
{
    return (self.webViewLeftConstraint.constant == 0) ? NO : YES;
}

-(void)tocHideWithDuration:(CGFloat)duration
{
    // Clear alerts
    [self showAlert:@""];
    
    // Ensure one exists to be hidden.
    [UIView animateWithDuration: duration
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{
                         self.webView.transform = CGAffineTransformIdentity;
                         self.bottomBarView.transform = CGAffineTransformIdentity;
                         self.bottomBarView.alpha = 1.0f;
                         self.webViewLeftConstraint.constant = 0;
                         [self.view.superview layoutIfNeeded];
                     }completion: ^(BOOL done){

                         if(self.tocVC) [self tocViewControllerRemove];

                     }];
}

-(void)tocShowWithDuration:(CGFloat)duration
{
    // Clear alerts
    [self showAlert:@""];

    // Ensure the toc is rebuilt from scratch! Very weird toc scroll view
    // resizing issues (can't scroll up to bottom toc entry sometimes, etc)
    // when choosing different article languages otherwise!
    if(self.tocVC) [self tocViewControllerRemove];
    
    [self tocViewControllerAdd];
    
    [self.tocVC centerCellForWebViewTopMostSectionAnimated:NO];

    CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
    CGAffineTransform xf = CGAffineTransformMakeScale(webViewScale, webViewScale);

    [UIView animateWithDuration: duration
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{
                         self.webView.transform = xf;
                         self.bottomBarView.transform = xf;
                         self.bottomBarView.alpha = 0.0f;
                         self.webViewLeftConstraint.constant = [self tocGetWidthForWebViewScale:webViewScale];
                         [self.view.superview layoutIfNeeded];
                     }completion: ^(BOOL done){
                         [self.view setNeedsUpdateConstraints];
                     }];
}

- (void)tocViewControllerAdd
{
    self.tocVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"TOCViewController"];
    self.tocVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.tocVC.webVC = self;

    [self addChildViewController:self.tocVC];

    [self.view setNeedsUpdateConstraints];
        
    [self.view addSubview:self.tocVC.view];

    [self.tocVC didMoveToParentViewController:self];

    // Make the toc's scroll view not scroll until the swipe recognizer fails.
    [self.tocVC.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.tocSwipeLeftRecognizer];
    [self.tocVC.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.tocSwipeRightRecognizer];

    [self.view.superview layoutIfNeeded];
}

- (void)tocViewControllerRemove
{
    [self.tocVC willMoveToParentViewController:nil];
    [self.tocVC.view removeFromSuperview];
    [self.tocVC removeFromParentViewController];
    
    self.tocVC = nil;
}

-(void)tocHide
{
    [self tocHideWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

-(void)tocShow
{
    [self tocShowWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

-(void)tocToggle
{
    // Clear alerts
    [self showAlert:@""];

    if ([self tocDrawerIsOpen]) {
        [self tocHide];
    }else{
        [self tocShow];
    }
}

-(void)tocSetupSwipeGestureRecognizers
{
    self.tocSwipeLeftRecognizer =
    [[UISwipeGestureRecognizer alloc] initWithTarget: self
                                              action: @selector(tocSwipeLeftHandler:)];
    
    self.tocSwipeRightRecognizer =
    [[UISwipeGestureRecognizer alloc] initWithTarget: self
                                              action: @selector(tocSwipeRightHandler:)];

    [self tocSetupSwipeGestureRecognizer: self.tocSwipeLeftRecognizer
                            forDirection: UISwipeGestureRecognizerDirectionLeft];

    [self tocSetupSwipeGestureRecognizer: self.tocSwipeRightRecognizer
                            forDirection: UISwipeGestureRecognizerDirectionRight];
}

-(void)tocSetupSwipeGestureRecognizer: (UISwipeGestureRecognizer *)recognizer
                         forDirection: (UISwipeGestureRecognizerDirection)direction
{
    recognizer.delegate = self;

    recognizer.direction = direction;
    
    [self.view addGestureRecognizer:recognizer];

    // Make the web view's scroll view not scroll until the swipe recognizer fails.
    [self.webView.scrollView.panGestureRecognizer requireGestureRecognizerToFail:recognizer];
    
}

-(void)tocSwipeLeftHandler:(UISwipeGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded){
        [self tocHide];
    }
}

-(void)tocSwipeRightHandler:(UISwipeGestureRecognizer *)recognizer
{
    NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;
    if (!currentArticleTitle || (currentArticleTitle.length == 0)) return;

    if (recognizer.state == UIGestureRecognizerStateEnded){
        [self tocShow];
    }
}

-(CGFloat)tocGetWebViewScaleWhenTOCVisible
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.67f : 0.72f);
    }else{
        return (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.45f : 0.65f);
    }
}

-(CGFloat)tocGetWidthForWebViewScale:(CGFloat)webViewScale
{
    return self.view.frame.size.width * (1.0f - webViewScale);
}

-(void)tocConstrainView
{
    if (!self.tocVC) return;
    
    [self.tocVC.view removeConstraintsOfViewFromView:self.view];

    CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
    
    NSDictionary *views = @{
                            @"view": self.view,
                            @"tocView": self.tocVC.view,
                            @"webView": self.webView
                            };
    
    NSDictionary *metrics = @{
                              @"tocInitialWidth": @([self tocGetWidthForWebViewScale:webViewScale])
                              };
    
    NSArray *constraints =
    @[
      @[
          [NSLayoutConstraint constraintWithItem: self.tocVC.view
                                       attribute: NSLayoutAttributeRight
                                       relatedBy: NSLayoutRelationEqual
                                          toItem: self.webView
                                       attribute: NSLayoutAttributeLeft
                                      multiplier: 1.0
                                        constant: 0]
          ]
      ,
      [NSLayoutConstraint constraintsWithVisualFormat: @"H:[tocView(==tocInitialWidth@1000)]"
                                              options: 0
                                              metrics: metrics
                                                views: views]
      ,
      [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[tocView]|"
                                              options: 0
                                              metrics: metrics
                                                views: views]
      ];
    
    [self.view addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

-(CGFloat)tocGetPercentOnscreen
{
    CGFloat defaultWebViewScaleWhenTOCVisible = [self tocGetWebViewScaleWhenTOCVisible];
    CGFloat defaultTOCWidth = [self tocGetWidthForWebViewScale:defaultWebViewScaleWhenTOCVisible];
    return 1.0f - (fabsf(self.tocVC.view.frame.origin.x) / defaultTOCWidth);
}

-(void)tocScrollWebViewToPoint: (CGPoint)point
                      duration: (CGFloat)duration
                   thenHideTOC: (BOOL)hideTOC
{
    point.x = self.webView.scrollView.contentOffset.x;
    
    [UIView animateWithDuration: duration
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{

                         // Not using "setContentOffset:animated:" so duration of animation
                         // can be controlled and action can be taken after animation completes.
                         self.webView.scrollView.contentOffset = point;

                     } completion:^(BOOL done){
                         
                         // Record the new scroll location.
                         [self saveWebViewScrollOffset];
                         // Toggle toc.
                         if (hideTOC) [self tocHide];
                     }];
}

#pragma mark UIContainerViewControllerCallbacks

-(BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return YES;
}

-(BOOL)shouldAutomaticallyForwardRotationMethods
{
    return YES;
}

#pragma mark KVO

-(void)observeValueForKeyPath: (NSString *)keyPath
                     ofObject: (id)object
                       change: (NSDictionary *)change
                      context: (void *)context
{
    if (
        (object == self.webView.scrollView)
        &&
        [keyPath isEqual:@"contentSize"]
        ) {
        [object preventHorizontalScrolling];
    }
}

#pragma mark Dealloc

-(void)dealloc
{
    [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize"];
}

#pragma mark Webview obj-c to javascript bridge

-(void)resetBridge
{
    // This needs to be called before sending a new page of html to the embedded UIWebView.
    // The bridge is the web view's delegate, and one of the web view delegate methods which
    // the bridge implements is "webViewDidFinishLoad:". This method only gets called the first
    // time a page is displayed unless the bridge is reset before beginning to send a page of
    // html. "webViewDidFinishLoad:" seems the only *reliable* way of being notified when the
    // page dom has been loaded and the web view's view had taken on the size of the content
    // it is rendering. It is only then that we can scroll to a saved article's previous
    // scroll offsets.

    // Because the bridge is a property now, rather than a private var, ARC should take care of
    // cleanup when the bridge is reset.
//TODO: confirm this comment ^
    self.bridge = [[CommunicationBridge alloc] initWithWebView:self.webView];
    [self.bridge addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
        //NSLog(@"QQQ HEY DOMLoaded!");
    }];

    __weak WebViewController *weakSelf = self;
    [self.bridge addListener:@"linkClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSString *href = payload[@"href"];
        
        [weakSelf tocHide];
        
        if ([href hasPrefix:@"/wiki/"]) {
            NSString *title = [href substringWithRange:NSMakeRange(6, href.length - 6)];

            [weakSelf navigateToPage: title
                              domain: [SessionSingleton sharedInstance].currentArticleDomain
                     discoveryMethod: DISCOVERY_METHOD_LINK];
        }else if ([href hasPrefix:@"//"]) {
            href = [@"http:" stringByAppendingString:href];
            
NSString *msg = [NSString stringWithFormat:@"To do: add code for navigating to external link: %@", href];
[weakSelf.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"alert('%@')", msg]];

        } else if ([href hasPrefix:@"http:"] || [href hasPrefix:@"https:"]) {
            // A standard link.
            // TODO: make all of the stuff above parse the URL into parts
            // unless it's /wiki/ or #anchor style.
            // Then validate if it's still in Wikipedia land and branch appropriately.
            if ([SessionSingleton sharedInstance].zeroConfigState.disposition &&
                [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroWarnWhenLeaving"]) {
                weakSelf.externalUrl = href;
                UIAlertView *dialog = [[UIAlertView alloc]
                                       initWithTitle:MWLocalizedString(@"zero-interstitial-title", nil)
                                       message:MWLocalizedString(@"zero-interstitial-leave-app", nil)
                                       delegate:weakSelf
                                       cancelButtonTitle:MWLocalizedString(@"zero-interstitial-cancel", nil)
                                       otherButtonTitles:MWLocalizedString(@"zero-interstitial-continue", nil)
                                       , nil];
                [dialog show];
            } else {
                NSURL *url = [NSURL URLWithString:href];
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }];

    [self.bridge addListener:@"editClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        [weakSelf tocHide];
        weakSelf.sectionToEditIndex = [[payload[@"href"] stringByReplacingOccurrencesOfString:@"edit_section_" withString:@""] integerValue];

        [weakSelf.self showSectionEditor];
    }];

    [self.bridge addListener:@"nonAnchorTouchEndedWithoutDragging" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSLog(@"nonAnchorTouchEndedWithoutDragging = %@", payload);
        // nonAnchorTouchEndedWithoutDragging is used so TOC may be hidden if user tapped, but did *not* drag.
        // Used because UIWebView is difficult to attach one-finger touch events to.
        [weakSelf tocHide];
    }];

    self.unsafeToScroll = NO;
    self.scrollOffset = CGPointZero;
}

#pragma mark History

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Ensure the web VC is the top VC.
    [self.navigationController popToViewController:self animated:YES];

    [self showAlert:@""];
}

#pragma Saved Pages

-(void)saveCurrentPage
{
    NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                                                  domain: [SessionSingleton sharedInstance].currentArticleDomain];
    
    if (!articleID) return;
    
    Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
    
    Saved *alreadySaved = (Saved *)[articleDataContext_.mainContext getEntityForName: @"Saved" withPredicateFormat: @"article == %@", article];
    
    NSLog(@"SAVE PAGE FOR %@, alreadySaved = %@", article.title, alreadySaved);
    if (article && !alreadySaved) {
        NSLog(@"SAVED PAGE %@", article.title);
        // Save!
        Saved *saved = [NSEntityDescription insertNewObjectForEntityForName:@"Saved" inManagedObjectContext:articleDataContext_.mainContext];
        saved.dateSaved = [NSDate date];
        [article addSavedObject:saved];
        
        NSError *error = nil;
        [articleDataContext_.mainContext save:&error];
        NSLog(@"SAVE PAGE ERROR = %@", error);
    }
}

#pragma mark Web view scroll offset recording

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(!decelerate) [self scrollViewScrollingEnded:scrollView];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self scrollViewScrollingEnded:scrollView];
}

-(void)scrollViewScrollingEnded:(UIScrollView *)scrollView
{
    if (scrollView == self.webView.scrollView) {
        // Once we've started scrolling around don't allow the webview delegate to scroll
        // to a saved position! Super annoying otherwise.
        self.unsafeToScroll = YES;

        //[self printLiveContentLocationTestingOutputToConsole];
        //NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
        [self saveWebViewScrollOffset];
        
        TOCViewController *tocVC = [self searchForChildViewControllerOfClass:[TOCViewController class]];
        if (tocVC) [tocVC centerCellForWebViewTopMostSectionAnimated:YES];

        self.pullToRefreshView.alpha = 0.0f;
    }
}

-(void)saveWebViewScrollOffset
{
    [articleDataContext_.mainContext performBlockAndWait:^(){
        // Save scroll location
        NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                                                      domain: [SessionSingleton sharedInstance].currentArticleDomain];
        if (articleID) {
            Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
            if (article) {
                article.lastScrollX = @(self.webView.scrollView.contentOffset.x);
                article.lastScrollY = @(self.webView.scrollView.contentOffset.y);
                NSError *error = nil;
                [articleDataContext_.mainContext save:&error];
            }
        }
    }];
}

#pragma mark Web view html content live location retrieval

-(void)printLiveContentLocationTestingOutputToConsole
{
    // Test with the top image (presently) on the San Francisco article.
    // (would test p.x and p.y against CGFLOAT_MAX to ensure good value was retrieved)
    CGPoint p = [self.webView getScreenCoordsForHtmlImageWithSrc:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/da/SF_From_Marin_Highlands3.jpg/280px-SF_From_Marin_Highlands3.jpg"];
    NSLog(@"p = %@", NSStringFromCGPoint(p));

    CGPoint p2 = [self.webView getWebViewCoordsForHtmlImageWithSrc:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/da/SF_From_Marin_Highlands3.jpg/280px-SF_From_Marin_Highlands3.jpg"];
    NSLog(@"p2 = %@", NSStringFromCGPoint(p2));

    // Also test location of second section on page.
    // (would test r with CGRectIsNull(r) to ensure good values were retrieved)
    CGRect r = [self.webView getScreenRectForHtmlElementWithId:@"content_block_1"];
    NSLog(@"r = %@", NSStringFromCGRect(r));

    CGRect r2 = [self.webView getWebViewRectForHtmlElementWithId:@"content_block_1"];
    NSLog(@"r2 = %@", NSStringFromCGRect(r2));
}

-(void)debugScrollLeadSanFranciscoArticleImageToTopLeft
{
    // Awesome! Now works regarless of pinch-zoom scale!
    CGPoint p = [self.webView getWebViewCoordsForHtmlImageWithSrc:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/da/SF_From_Marin_Highlands3.jpg/280px-SF_From_Marin_Highlands3.jpg"];
    [self.webView.scrollView setContentOffset:p animated:YES];
}

#pragma mark Web view scroll offset - using it!

-(void)webViewFinishedLoading
{
    if(!self.unsafeToScroll){
        [self.webView.scrollView setContentOffset:self.scrollOffset animated:NO];
    }
    
    [self.tocVC centerCellForWebViewTopMostSectionAnimated:NO];
}

#pragma mark Scroll hiding keyboard threshold

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    /*
    // Hides nav bar when a scroll threshold is exceeded. Probably only want to do this
    // when the webView's scrollView scrolls. Probably also want to set the status bar to
    // be not transparent when the nav bar is hidden - if not possible could position a
    // view just behind it, but above the webView.
    if (scrollView == self.webView.scrollView) {
        CGFloat f = scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y;
        if (f < -55 && !self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }else if (f > 55 && self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            //[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        }
    }
    */

    // Hide the keyboard if it was visible when the results are scrolled, but only if
    // the results have been scrolled in excess of some small distance threshold first.
    // This prevents tiny scroll adjustments, which seem to occur occasionally for some
    // reason, from causing the keyboard to hide when the user is typing on it!
    CGFloat distanceScrolled = scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y;
    CGFloat fabsDistanceScrolled = fabs(distanceScrolled);
    
    if (fabsDistanceScrolled > HIDE_KEYBOARD_ON_SCROLL_THRESHOLD) {
        [self hideKeyboard];
        //NSLog(@"Keyboard Hidden!");
    }
    
    [self updatePullToRefreshForScrollView:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    scrollViewDragBeganVerticalOffset_ = scrollView.contentOffset.y;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [self.tocVC centerCellForWebViewTopMostSectionAnimated:NO];
    [self saveWebViewScrollOffset];
}

#pragma Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString *)cleanTitle:(NSString *)title
{
    return [title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

#pragma mark Article loading ops

- (void)navigateToPage: (NSString *)title
                domain: (NSString *)domain
       discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod
{
    NSString *cleanTitle = [self cleanTitle:title];
    
    // Don't try to load nothing. Core data takes exception with such nonsense.
    if (cleanTitle == nil) return;
    if (cleanTitle.length == 0) return;
    
    [self hideKeyboard];
    
    // Show loading message
    [self showAlert:MWLocalizedString(@"search-loading-section-zero", nil)];
    
    [self retrieveArticleForPageTitle: cleanTitle
                               domain: domain
                      discoveryMethod: [self getStringForDiscoveryMethod:discoveryMethod]];
}

-(void)reloadCurrentArticle{
    NSString *title = [SessionSingleton sharedInstance].currentArticleTitle;
    NSString *domain = [SessionSingleton sharedInstance].currentArticleDomain;
    [self navigateToPage: title
                  domain: domain
         discoveryMethod: DISCOVERY_METHOD_SEARCH];
}

-(void)reloadCurrentArticleInvalidatingCache
{
    // Mark article for refreshing so its core data records will be reloaded.
    // (Needs to be done on worker context as worker context changes bubble up through
    // main context too - so web view controller accessing main context will see changes.)

    NSManagedObjectID *articleID =
    [articleDataContext_.mainContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                   domain: [SessionSingleton sharedInstance].currentArticleDomain];
    
    if (articleID) {
        [articleDataContext_.workerContext performBlockAndWait:^(){
            Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
            if (article) {
                article.needsRefresh = @YES;
                NSError *error = nil;
                [articleDataContext_.workerContext save:&error];
                NSLog(@"error = %@", error);
            }
        }];
        [self reloadCurrentArticle];
    }
}

- (void)retrieveArticleForPageTitle: (NSString *)pageTitle
                             domain: (NSString *)domain
                    discoveryMethod: (NSString *)discoveryMethod
{
    // Cancel any in-progress article retrieval operations
    [[QueuesSingleton sharedInstance].articleRetrievalQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].searchQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].thumbnailQ cancelAllOperations];

    __block NSManagedObjectID *articleID =
    [articleDataContext_.mainContext getArticleIDForTitle: pageTitle
                                                   domain: domain];
    BOOL needsRefresh = NO;

    if (articleID) {
        Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
        
        // If article with sections just show them (unless needsRefresh is YES)
        if (article.section.count > 0 && !article.needsRefresh.boolValue) {
            [self displayArticle:articleID mode:DISPLAY_ALL_SECTIONS];
            [self showAlert:MWLocalizedString(@"search-loading-article-loaded", nil)];
            [self showAlert:@""];
            return;
        }
        needsRefresh = article.needsRefresh.boolValue;
    }

    // Retrieve first section op
    DownloadLeadSectionOp *firstSectionOp =
    [[DownloadLeadSectionOp alloc] initForPageTitle:pageTitle domain:[SessionSingleton sharedInstance].currentArticleDomain completionBlock:^(NSDictionary *dataRetrieved){

        Article *article = nil;
        
        if (!articleID) {
            article = [NSEntityDescription
                insertNewObjectForEntityForName:@"Article"
                inManagedObjectContext:articleDataContext_.workerContext
            ];
            article.title = pageTitle;
            article.dateCreated = [NSDate date];
            article.site = [SessionSingleton sharedInstance].site;
            article.domain = [SessionSingleton sharedInstance].currentArticleDomain;
            article.domainName = [SessionSingleton sharedInstance].currentArticleDomainName;
            articleID = article.objectID;
        }else{
            article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
        }

        if (needsRefresh) {
            // If and article needs refreshing remove its sections so they get reloaded too.
            for (Section *thisSection in [article.section copy]) {
                [articleDataContext_.workerContext deleteObject:thisSection];
            }
        }

        // If "needsRefresh", an existing article's data is being retrieved again, so these need
        // to be updated whether a new article record is being inserted or not as data may have
        // changed since the article record was first created.
        article.languagecount = dataRetrieved[@"languagecount"];
        article.lastmodified = dataRetrieved[@"lastmodified"];
        article.lastmodifiedby = dataRetrieved[@"lastmodifiedby"];
        article.redirected = dataRetrieved[@"redirected"];
        //NSDateFormatter *anotherDateFormatter = [[NSDateFormatter alloc] init];
        //[anotherDateFormatter setDateStyle:NSDateFormatterLongStyle];
        //[anotherDateFormatter setTimeStyle:NSDateFormatterShortStyle];
        //NSLog(@"formatted lastmodified = %@", [anotherDateFormatter stringFromDate:article.lastmodified]);

        // Associate thumbnail with article.
        // If search result for this pageTitle had a thumbnail url associated with it, see if
        // a core data image object exists with a matching sourceURL. If so make the article
        // thumbnailImage property point to that core data image object. This associates the
        // search result thumbnail with the article.
        
        NSArray *result = [NAV.currentSearchResultsOrdered filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"(title == %@) AND (thumbnail.source.length > 0)", pageTitle]
        ];
        if (result.count == 1) {
            NSString *thumbURL = result[0][@"thumbnail"][@"source"];
            thumbURL = [thumbURL getUrlWithoutScheme];
            Image *thumb = (Image *)[articleDataContext_.workerContext getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", thumbURL];
            if (thumb) article.thumbnailImage = thumb;
        }

        article.lastScrollX = @0.0f;
        article.lastScrollY = @0.0f;

        // Get article section zero html
        NSArray *sectionsRetrieved = dataRetrieved[@"sections"];
        NSDictionary *section0Dict = (sectionsRetrieved.count >= 1) ? sectionsRetrieved[0] : nil;

        // If there was only one section then we have what we need so no refresh
        // is needed. Otherwise leave needsRefresh set to YES until subsequent sections
        // have been retrieved. Reminder: "onlyrequestedsections" is not used
        // by the mobileview query so that sectionsRetrieved.count will
        // reflect the article's total number of sections here ("sections"
        // was set to "0" though so only the first section entry actually has
        // any html). This fixes the bug which caused subsequent sections to never
        // be retrieved if the article was navigated away from before they had loaded.
        article.needsRefresh = (sectionsRetrieved.count == 1) ? @NO : @YES;

        NSString *section0HTML = @"";
        if (section0Dict && [section0Dict[@"id"] isEqual: @0] && section0Dict[@"text"]) {
            section0HTML = section0Dict[@"text"];
        }

        // Add sections for article
        Section *section0 = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:articleDataContext_.workerContext];
        section0.index = @0;
        section0.title = @"";
        section0.dateRetrieved = [NSDate date];
        section0.html = section0HTML;
        section0.anchor = @"";
        article.section = [NSSet setWithObjects:section0, nil];

        // Don't add multiple history items for the same article or back-forward button
        // behavior becomes a confusing mess.
        if(article.history.count == 0){
            // Add history for article
            History *history0 = [NSEntityDescription insertNewObjectForEntityForName:@"History" inManagedObjectContext:articleDataContext_.workerContext];
            history0.dateVisited = [NSDate date];
            //history0.dateVisited = [NSDate dateWithDaysBeforeNow:31];
            history0.discoveryMethod = discoveryMethod;
            [article addHistoryObject:history0];
        }

        // Save the article!
        NSError *error = nil;
        [articleDataContext_.workerContext save:&error];

        if (error) {
            NSLog(@"error = %@", error);
            NSLog(@"error = %@", error.localizedDescription);
        }

        [self displayArticle:articleID mode:DISPLAY_LEAD_SECTION];
        [self showAlert:MWLocalizedString(@"search-loading-section-remaining", nil)];

    } cancelledBlock:^(NSError *error){

        // Remove the article so it doesn't get saved.
        if (articleID) {
            Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
            [articleDataContext_.workerContext deleteObject:article];
        }

    } errorBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
        if (articleID) {
            // Remove the article so it doesn't get saved.
            Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
            [articleDataContext_.workerContext deleteObject:article];
        }
    }];

    firstSectionOp.delegate = self;
    
    // Retrieve remaining sections op (dependent on first section op)
    DownloadNonLeadSectionsOp *remainingSectionsOp = [[DownloadNonLeadSectionsOp alloc] initForPageTitle:pageTitle domain:[SessionSingleton sharedInstance].currentArticleDomain completionBlock:^(NSArray *sectionsRetrieved){
        
        // Just in case the article wasn't created during the "parent" operation.
        if (!articleID) return;
        
        // The completion block happens on non-main thread, so must get article from articleID again.
        // Because "you can only use a context on a thread when the context was created on that thread"
        // this must happen on workerContext as well (see: http://stackoverflow.com/a/6356201/135557)
        Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];

        //Non-lead sections have been retreived so set needsRefresh to NO.
        article.needsRefresh = @NO;

        NSMutableArray *sectionText = [@[] mutableCopy];
        for (NSDictionary *section in sectionsRetrieved) {
            if (![section[@"id"] isEqual: @0]) {
                
                NSString *sectionHTMLWithID = [self surroundHTML:section[@"text"] withDivForSection:section[@"id"]];
                
                [sectionText addObject:sectionHTMLWithID];
                
                // Add sections for article
                Section *thisSection = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:articleDataContext_.workerContext];
                thisSection.index = section[@"id"];
                thisSection.title = section[@"line"];
                thisSection.html = section[@"text"];
                thisSection.tocLevel = section[@"toclevel"];
                thisSection.dateRetrieved = [NSDate date];
                thisSection.anchor = (section[@"anchor"]) ? section[@"anchor"] : @"";
                [article addSectionObject:thisSection];
            }
        }

        NSError *error = nil;
        [articleDataContext_.workerContext save:&error];
        
        [self displayArticle:articleID mode:DISPLAY_APPEND_NON_LEAD_SECTIONS];
        [self showAlert:MWLocalizedString(@"search-loading-article-loaded", nil)];
        [self showAlert:@""];

    } cancelledBlock:^(NSError *error){
        [self showAlert:@""];
    } errorBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
    }];

    remainingSectionsOp.delegate = self;
    
    // Retrieval of remaining sections depends on retrieving first section
    [remainingSectionsOp addDependency:firstSectionOp];
    
    [[QueuesSingleton sharedInstance].articleRetrievalQ addOperation:remainingSectionsOp];
    [[QueuesSingleton sharedInstance].articleRetrievalQ addOperation:firstSectionOp];
}

-(NSString *)getStringForDiscoveryMethod:(ArticleDiscoveryMethod)method
{
    switch (method) {
        case DISCOVERY_METHOD_RANDOM:
            return @"random";
            break;
        case DISCOVERY_METHOD_LINK:
            return @"link";
            break;
        case DISCOVERY_METHOD_SEARCH:
        default:
            return @"search";
            break;
    }
}

#pragma mark Progress report

-(void)opProgressed:(MWNetworkOp *)op;
{
    return;
    if (op.dataRetrieved.length) {
        NSLog(@"Receive progress: %lu of %lu", (unsigned long)op.dataRetrieved.length, (unsigned long)op.dataRetrievedExpectedLength);
    }else{
        NSLog(@"Send progress: %@ of %@", op.bytesWritten, op.bytesExpectedToWrite);
    }
}

#pragma mark HTML added just before display

-(NSString *)surroundHTML:(NSString *)html withDivForSection:(NSNumber *)sectionIndex
{
    // Just before section html is sent across the bridge to the web view, add section identifiers around
    // each section. This will make it easy to identify section offsets for the purpose of scrolling the
    // web view to a given section. Do not save this html to the core data store - this way it can be changed
    // later if needed (to a div etc).
    
    return [NSString stringWithFormat:
        @"<div class='content_block' id='content_block_%@'>\
            <span class='edit_section' id='edit_section_%d'>\
            </span>\
            %@\
        </div>\
        ", sectionIndex, sectionIndex.integerValue, html];
}

-(NSString *)addTitle:(NSString *)title toHTML:(NSString *)html
{
    // Add title just before section html is sent across the bridge to the web view.
    // Do not save this html to the core data store.
    return [NSString stringWithFormat:@"<h1 id=\"title\">%@</h1>%@", title, html];
}

#pragma mark Display article from core data

- (void)displayArticle:(NSManagedObjectID *)articleID mode:(DisplayMode)mode
{
    // Get sorted sections for this article (sorts the article.section NSSet into sortedSections)
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];

    Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];

    if (!article) return;
    [SessionSingleton sharedInstance].currentArticleTitle = article.title;
    [SessionSingleton sharedInstance].currentArticleDomain = article.domain;
    MWLanguageInfo *languageInfo = [MWLanguageInfo languageInfoForCode:article.domain];

    NSNumber *langCount = article.languagecount;
    
    [self updateBottomBarButtonsEnabledStateWithLangCount:langCount];

    NSArray *sortedSections = [article.section sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSMutableArray *sectionTextArray = [@[] mutableCopy];
    
    for (Section *section in sortedSections) {
        if (mode == DISPLAY_APPEND_NON_LEAD_SECTIONS) {
            if (section.index.integerValue == 0) continue;
        }
        if (section.html){

            [section createImageRecordsForHtmlOnContext:articleDataContext_.mainContext];

            NSString *sectionHTML = section.html;
            if ([section.index isEqualToNumber:@(0)]) {
                sectionHTML = [self addTitle:article.title toHTML:sectionHTML];
            }

            NSString *sectionHTMLWithID = [self surroundHTML:sectionHTML withDivForSection:section.index];

            [sectionTextArray addObject:sectionHTMLWithID];
        }
        if (mode == DISPLAY_LEAD_SECTION) break;
    }

    // Pull the scroll offset out so the article object doesn't have to be passed into the block below.
    CGPoint scrollOffset = CGPointMake(article.lastScrollX.floatValue, article.lastScrollY.floatValue);

    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        if (mode != DISPLAY_APPEND_NON_LEAD_SECTIONS) {
            // See comments inside resetBridge.
            [self resetBridge];
        }
        
        self.scrollOffset = scrollOffset;
        
        // Join article sections text
        NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
        NSString *htmlStr = [sectionTextArray componentsJoinedByString:joint];
        
        // Display all sections
        [self.bridge sendMessage: @"setLanguage"
                     withPayload: @{
                                   @"lang": languageInfo.code,
                                   @"dir": languageInfo.dir
                                   }];
        
        [self.bridge sendMessage:@"append" withPayload:@{@"html": htmlStr}];

        if ([self tocDrawerIsOpen]) {
            // Drawer is already open, so just refresh the toc quickly w/o animation.
            [self tocShowWithDuration:0.0f];
        }
    }];
}

#pragma mark Bottom bar button methods

//TODO: Pull bottomBarView and into own object (and its subviews - the back and forward view/buttons/methods, etc).

- (IBAction)backButtonPushed:(id)sender
{
    NSManagedObjectID *historyId = self.adjacentHistoryIDs[@"before"];
    if (historyId){
        History *history = (History *)[articleDataContext_.mainContext objectWithID:historyId];
        [self navigateToPage: history.article.title
                      domain: history.article.domain
             discoveryMethod: DISCOVERY_METHOD_SEARCH];
    }
}

- (IBAction)forwardButtonPushed:(id)sender
{
    NSManagedObjectID *historyId = self.adjacentHistoryIDs[@"after"];
    if (historyId){
        History *history = (History *)[articleDataContext_.mainContext objectWithID:historyId];
        [self navigateToPage: history.article.title
                      domain: history.article.domain
             discoveryMethod: DISCOVERY_METHOD_SEARCH];
    }
}

-(NSDictionary *)getAdjacentHistoryIDs
{
    __block NSManagedObjectID *currentHistoryId = nil;
    __block NSManagedObjectID *beforeHistoryId = nil;
    __block NSManagedObjectID *afterHistoryId = nil;
    
    [articleDataContext_.workerContext performBlockAndWait:^(){
        
        NSError *error = nil;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName: @"History"
                                                  inManagedObjectContext: articleDataContext_.workerContext];
        [fetchRequest setEntity:entity];
        
        NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"dateVisited" ascending:YES selector:nil];
        
        [fetchRequest setSortDescriptors:@[dateSort]];
        
        error = nil;
        NSArray *historyEntities = [articleDataContext_.workerContext executeFetchRequest:fetchRequest error:&error];
        
        NSManagedObjectID *currentArticleId = [articleDataContext_.workerContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                                                               domain: [SessionSingleton sharedInstance].currentArticleDomain];
        for (NSUInteger i = 0; i < historyEntities.count; i++) {
            History *history = historyEntities[i];
            if (history.article.objectID == currentArticleId){
                currentHistoryId = history.objectID;
                if (i > 0) {
                    History *beforeHistory = historyEntities[i - 1];
                    beforeHistoryId = beforeHistory.objectID;
                }
                if ((i + 1) <= (historyEntities.count - 1)) {
                    History *afterHistory = historyEntities[i + 1];
                    afterHistoryId = afterHistory.objectID;
                }
                break;
            }
        }
    }];

    NSMutableDictionary *result = [@{} mutableCopy];
    if(beforeHistoryId) result[@"before"] = beforeHistoryId;
    if(currentHistoryId) result[@"current"] = currentHistoryId;
    if(afterHistoryId) result[@"after"] = afterHistoryId;

    return result;
}

-(void)updateBottomBarButtonsEnabledStateWithLangCount:(NSNumber *)langCount
{
    self.adjacentHistoryIDs = [self getAdjacentHistoryIDs];
    self.forwardButton.enabled = (self.adjacentHistoryIDs[@"after"]) ? YES : NO;
    self.backButton.enabled = (self.adjacentHistoryIDs[@"before"]) ? YES : NO;
    NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;
    self.tocButton.enabled = (currentArticleTitle && (currentArticleTitle.length > 0)) ? YES : NO;
    self.langButton.enabled = (langCount.integerValue > 1) ? YES : NO;
}

- (IBAction)tocButtonPushed:(id)sender
{
    [self tocToggle];
}

- (IBAction)languageButtonPushed:(id)sender
{
    [self showLanguages];
}

#pragma mark Scroll to last section after rotate

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                                                  domain: [SessionSingleton sharedInstance].currentArticleDomain];
    if (articleID) {
        Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];

        self.indexOfFirstOnscreenSectionBeforeRotate = [self.webView getIndexOfTopOnScreenElementWithPrefix:@"content_block_" count:article.section.count];
    }
    //self.view.alpha = 0.0f;

    [self tocHideWithDuration:0.0f];
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self performSelector:@selector(scrollToIndexOfFirstOnscreenSectionBeforeRotate) withObject:nil afterDelay:0.15f];
}

-(void)scrollToIndexOfFirstOnscreenSectionBeforeRotate{
    if(self.indexOfFirstOnscreenSectionBeforeRotate == -1)return;
    NSString *elementId = [NSString stringWithFormat:@"content_block_%ld", (long)self.indexOfFirstOnscreenSectionBeforeRotate];
    CGRect r = [self.webView getWebViewRectForHtmlElementWithId:elementId];
    if (CGRectIsNull(r)) return;
    CGPoint p = r.origin;
    p.x = self.webView.scrollView.contentOffset.x;
    [self.webView.scrollView setContentOffset:p animated:NO];

    [self.tocVC centerCellForWebViewTopMostSectionAnimated:NO];
}

#pragma mark Wikipedia Zero handling

-(void)zeroStateChanged: (NSNotification*) notification
{
    [[QueuesSingleton sharedInstance].zeroRatedMessageStringQ cancelAllOperations];

    if ([[[notification userInfo] objectForKey:@"state"] boolValue]) {
        DownloadWikipediaZeroMessageOp *zeroMessageRetrievalOp =
        [
         [DownloadWikipediaZeroMessageOp alloc]
         initForDomain: [SessionSingleton sharedInstance].currentArticleDomain
         completionBlock: ^(NSString *message) {
         
             if (message) {
                 dispatch_async(dispatch_get_main_queue(), ^(){
                 
                     NavBarTextField *textField = [NAV getNavBarItem:NAVBAR_TEXT_FIELD];
                     textField.placeholder = MWLocalizedString(@"search-field-placeholder-text-zero", nil);
                     
                     NAV.navBarStyle = NAVBAR_STYLE_NIGHT;
                     
                     [self showAlert:message];
                     [self promptFirstTimeZeroOnWithMessageIfAppropriate:message];
                 });
                 
                 // [self showHTMLAlert:message bannerImage:nil bannerColor:
                 // [UIColor colorWithWhite:0.0 alpha:1.0]];
             }
         } cancelledBlock:^(NSError *errorCancel) {
             NSLog(@"error w0 cancel");
         } errorBlock:^(NSError *errorError) {
             NSLog(@"error w0 error");
         }];

        [[QueuesSingleton sharedInstance].zeroRatedMessageStringQ addOperation:zeroMessageRetrievalOp];
        
    } else {
    
        NavBarTextField *textField = [NAV getNavBarItem:NAVBAR_TEXT_FIELD];
        textField.placeholder = MWLocalizedString(@"search-field-placeholder-text", nil);

        NAV.navBarStyle = NAVBAR_STYLE_DAY;
        [self showAlert:MWLocalizedString(@"zero-charged-verbiage", nil)];
        [self promptFirstTimeZeroOffIfAppropriate];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (1 == buttonIndex) {
        NSURL *url = [NSURL URLWithString:self.externalUrl];
        [[UIApplication sharedApplication] openURL:url];
    }
}

// Don't call this directly. Use promptFirstTimeZeroOnWithMessageIfAppropriate or promptFirstTimeZeroOffIfAppropriate
-(void) promptFirstTimeZeroOnOrOff:(NSString *) message
{
    self.externalUrl = MWLocalizedString(@"zero-webpage-url", nil);
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle: (message ? message : MWLocalizedString(@"zero-charged-verbiage", nil))
                           message:MWLocalizedString(@"zero-learn-more", nil)
                           delegate:self
                           cancelButtonTitle:MWLocalizedString(@"zero-learn-more-no-thanks", nil)
                           otherButtonTitles:MWLocalizedString(@"zero-learn-more-learn-more", nil)
                           , nil];
    [dialog show];
}

-(void) promptFirstTimeZeroOnWithMessageIfAppropriate:(NSString *) message {
    if (![SessionSingleton sharedInstance].zeroConfigState.zeroOnDialogShownOnce) {
        [[SessionSingleton sharedInstance].zeroConfigState setZeroOnDialogShownOnce];
        [self promptFirstTimeZeroOnOrOff:message];
    }
}

-(void) promptFirstTimeZeroOffIfAppropriate {
    if (![SessionSingleton sharedInstance].zeroConfigState.zeroOffDialogShownOnce) {
        [[SessionSingleton sharedInstance].zeroConfigState setZeroOffDialogShownOnce];
        [self promptFirstTimeZeroOnOrOff:nil];
    }
}

#pragma mark Pull to refresh

-(void)setupPullToRefresh
{
    self.pullToRefreshLabel = [[UILabel alloc] init];
    self.pullToRefreshLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pullToRefreshLabel.backgroundColor = [UIColor clearColor];
    self.pullToRefreshLabel.textAlignment = NSTextAlignmentCenter;
    self.pullToRefreshLabel.numberOfLines = 2;
    self.pullToRefreshLabel.font = [UIFont systemFontOfSize:10];
    self.pullToRefreshLabel.textColor = [UIColor darkGrayColor];
    
    self.pullToRefreshView = [[UIView alloc] init];
    self.pullToRefreshView.alpha = 0.0f;
    self.pullToRefreshView.backgroundColor = [UIColor clearColor];
    self.pullToRefreshView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.pullToRefreshView];
    [self.pullToRefreshView addSubview:self.pullToRefreshLabel];
    
    [self constrainPullToRefresh];
}

-(void)constrainPullToRefresh
{
    self.pullToRefreshViewBottomConstraint =
        [NSLayoutConstraint constraintWithItem: self.pullToRefreshView
                                     attribute: NSLayoutAttributeBottom
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: self.view
                                     attribute: NSLayoutAttributeTop
                                    multiplier: 1.0
                                      constant: 0];
    
    NSDictionary *viewsDictionary = @{
                                      @"pullToRefreshView": self.pullToRefreshView,
                                      @"pullToRefreshLabel": self.pullToRefreshLabel,
                                      @"selfView": self.view
                                      };
    
    NSArray *viewConstraintArrays =
        @[
          [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[pullToRefreshView]|"
                                                  options: 0
                                                  metrics: nil
                                                    views: viewsDictionary],
          @[self.pullToRefreshViewBottomConstraint],
          [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-[pullToRefreshLabel]-|"
                                                  options: 0
                                                  metrics: nil
                                                    views: viewsDictionary],
          [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[pullToRefreshLabel]|"
                                                  options: 0
                                                  metrics: nil
                                                    views: viewsDictionary],
          ];
    
    [self.view addConstraints:[viewConstraintArrays valueForKeyPath:@"@unionOfArrays.self"]];
}

- (void)updatePullToRefreshForScrollView:(UIScrollView *)scrollView
{
    CGFloat pullDistance = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) ? 85.0f : 55.0f;

    UIGestureRecognizerState state = ((UIPinchGestureRecognizer *)scrollView.pinchGestureRecognizer).state;

    NSString *title = [SessionSingleton sharedInstance].currentArticleTitle;

    BOOL safeToShow =
        (!scrollView.decelerating)
        &&
        ([QueuesSingleton sharedInstance].articleRetrievalQ.operationCount == 0)
        &&
        (![self tocDrawerIsOpen])
        &&
        (state == UIGestureRecognizerStatePossible)
        &&
        (title && (title.length > 0))
    ;

    //NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
    if ((scrollView.contentOffset.y < 0.0f)){

        self.pullToRefreshViewBottomConstraint.constant = -scrollView.contentOffset.y;
        //self.pullToRefreshViewBottomConstraint.constant = -(fmaxf(scrollView.contentOffset.y, -self.pullToRefreshView.frame.size.height));

        if (safeToShow) {
            self.pullToRefreshView.alpha = 1.0f;
        }

        NSString *lineOneText = @"";
        NSString *lineTwoText = MWLocalizedString(@"article-pull-to-refresh-prompt", nil);

        if (scrollView.contentOffset.y > -(pullDistance * 0.35)){
            lineOneText = @"▫︎ ▫︎ ▫︎ ▫︎ ▫︎";
        }else if (scrollView.contentOffset.y > -(pullDistance * 0.52)){
            lineOneText = @"▫︎ ▫︎ ▪︎ ▫︎ ▫︎";
        }else if (scrollView.contentOffset.y > -(pullDistance * 0.7)){
            lineOneText = @"▫︎ ▪︎ ▪︎ ▪︎ ▫︎";
        }else if (scrollView.contentOffset.y > -pullDistance){
            lineOneText = @"▫︎ ▪︎ ▪︎ ▪︎ ▫︎";
        }else{
            lineOneText = @"▪︎ ▪︎ ▪︎ ▪︎ ▪︎";
            lineTwoText = MWLocalizedString(@"article-pull-to-refresh-is-refreshing", nil);
        }

        self.pullToRefreshLabel.text = [NSString stringWithFormat:@"%@\n%@", lineOneText, lineTwoText];
    }

    if (scrollView.contentOffset.y < -pullDistance) {
        if (safeToShow) {
            
            //NSLog(@"REFRESH NOW!!!!!");
            
            [self reloadCurrentArticleInvalidatingCache];
            
            [UIView animateWithDuration: 0.3f
                                  delay: 0.6f
                                options: UIViewAnimationOptionTransitionNone
                             animations: ^{
                                 self.pullToRefreshView.alpha = 0.0f;
                                 self.pullToRefreshViewBottomConstraint.constant = 0;
                                 [self.view layoutIfNeeded];
                                 scrollView.panGestureRecognizer.enabled = NO;
                             } completion: ^(BOOL done){
                                 scrollView.panGestureRecognizer.enabled = YES;
                             }];
        }
    }
}

@end
