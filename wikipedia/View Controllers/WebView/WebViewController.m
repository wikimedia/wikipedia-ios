//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewController.h"

#import "WikipediaAppUtils.h"
#import "DownloadWikipediaZeroMessageOp.h"
#import "ArticleDataContextSingleton.h"
#import "SectionEditorViewController.h"
#import "DownloadSectionsOp.h"
#import "ArticleCoreDataObjects.h"
#import "CommunicationBridge.h"
#import "TOCViewController.h"
#import "SessionSingleton.h"
#import "QueuesSingleton.h"
#import "TopMenuTextField.h"
#import "TopMenuTextFieldContainer.h"
#import "MWLanguageInfo.h"
#import "CenterNavController.h"
#import "Defines.h"
#import "MWPageTitle.h"
#import "UIViewController+SearchChildViewControllers.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "UIScrollView+NoHorizontalScrolling.h"
#import "UIViewController+HideKeyboard.h"
#import "UIWebView+HideScrollGradient.h"
#import "UIWebView+ElementLocation.h"
#import "UIView+RemoveConstraints.h"
#import "UIViewController+Alert.h"
#import "Section+ImageRecords.h"
#import "Section+LeadSection.h"
#import "NSString+Extras.h"
#import "PaddedLabel.h"
#import "DataMigrator.h"
#import "ArticleImporter.h"
#import "SyncAssetsFileOp.h"
#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "BottomMenuViewController.h"
#import "LanguagesViewController.h"
#import "ModalMenuAndContentViewController.h"
#import "UIViewController+ModalPresent.h"
#import "Section+DisplayHtml.h"
#import "EditFunnel.h"
#import "ProtectedEditAttemptFunnel.h"
#import "CoreDataHousekeeping.h"
#import "Article+Convenience.h"
#import "NSDate-Utilities.h"
#import "AccountCreationViewController.h"
#import "OnboardingViewController.h"
#import "TopMenuContainerView.h"
#import "WikiGlyph_Chars.h"
#import "UINavigationController+TopActionSheet.h"
#import "ReferencesVC.h"

//#import "UIView+Debugging.h"

#define TOC_TOGGLE_ANIMATION_DURATION @0.225f

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

@property (nonatomic) float relativeScrollOffsetBeforeRotate;
@property (nonatomic) NSUInteger sectionToEditId;

@property (strong, nonatomic) NSDictionary *adjacentHistoryIDs;
@property (strong, nonatomic) NSString *externalUrl;

@property (weak, nonatomic) IBOutlet UIView *bottomBarView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewRightConstraint;

@property (strong, nonatomic) TOCViewController *tocVC;
@property (strong, nonatomic) UISwipeGestureRecognizer *tocSwipeLeftRecognizer;
@property (strong, nonatomic) UISwipeGestureRecognizer *tocSwipeRightRecognizer;

@property (strong, nonatomic) IBOutlet PaddedLabel *zeroStatusLabel;

@property (nonatomic) BOOL unsafeToToggleTOC;

@property (weak, nonatomic) BottomMenuViewController *bottomMenuViewController;
@property (strong, nonatomic) ReferencesVC *referencesVC;
@property (weak, nonatomic) IBOutlet UIView *referencesContainerView;

@property (strong, nonatomic) NSLayoutConstraint *bottomBarViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *referencesContainerViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *referencesContainerViewHeightConstraint;

@property (copy) NSString *jumpToFragment;

@property (nonatomic) BOOL editable;
@property (copy) NSString *protectionStatus;

// These are presently only used by updateHistoryDateVisitedForArticleBeingNavigatedFrom method.
@property (strong, nonatomic) NSString *currentTitle;
@property (strong, nonatomic) NSString *currentDomain;

@end

#pragma mark Internal variables

@implementation WebViewController {
    CGFloat scrollViewDragBeganVerticalOffset_;
    ArticleDataContextSingleton *articleDataContext_;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (BOOL)prefersTopNavigationHidden
{
    return [self shouldShowOnboarding];
}

-(NavBarMode)navBarMode
{
    return NAVBAR_MODE_DEFAULT;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

#pragma mark View lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.zeroStatusLabel.text = @"";
    self.referencesVC = nil;
    
    self.sectionToEditId = 0;

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(webViewFinishedLoading)
                                                 name: @"WebViewFinishedLoading"
                                               object: nil];
    
    self.unsafeToScroll = NO;
    self.unsafeToToggleTOC = NO;
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

    [self fadeAlert];

    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
    
    scrollViewDragBeganVerticalOffset_ = 0.0f;
    
    // Ensure web view can appear beneath translucent nav bar when scrolled up
    for (UIView *subview in self.webView.subviews) {
        subview.clipsToBounds = NO;
    }

    // Ensure the keyboard hides if the web view is scrolled
    // We already are delegate from PullToRefreshViewController
    //self.webView.scrollView.delegate = self;

    self.webView.backgroundColor = [UIColor whiteColor];

    [self.webView hideScrollGradient];

    [self reloadCurrentArticleInvalidatingCache:NO];
    
    // Restrict the web view from scrolling horizonally.
    [self.webView.scrollView addObserver: self
                              forKeyPath: @"contentSize"
                                 options: NSKeyValueObservingOptionNew
                                 context: nil];

    [self.bottomBarView addObserver:self
                         forKeyPath: @"bounds"
                            options: NSKeyValueObservingOptionNew
                            context: nil];
    
    [self tocSetupSwipeGestureRecognizers];
    
    // UIWebView has a bug which causes a black bar to appear at
    // bottom of the web view if toc quickly dragged on and offscreen.
    self.webView.opaque = NO;
    
    // This is the first view that's opened when the app opens...
    // Perform any first-time data migration as needed.
    [self migrateDataIfNecessary];
    
    
    self.bottomBarViewBottomConstraint = nil;

    // This needs to be in viewDidLoad.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(languageItemSelectedNotification:)
                                                 name: @"LanguageItemSelected"
                                               object: nil];

    self.view.backgroundColor = CHROME_COLOR;
    






// Uncomment these lines only if testing onboarding!
// These lines allow the onboarding to run on every app cold start.
//[[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"ShowOnboarding"];
//[[NSUserDefaults standardUserDefaults] synchronize];



//self.referencesContainerView.layer.borderWidth = 10;
//self.referencesContainerView.layer.borderColor = [UIColor redColor].CGColor;

}

-(void)showAlert:(NSString *)alertText
{
    if ([self tocDrawerIsOpen]) return;

    // Don't show alerts if onboarding onscreen.
    if ([self shouldShowOnboarding]) return;

    [super showAlert:alertText];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([self shouldShowOnboarding]) {
        [self showOnboarding];

        // Ok to show the menu now. (The onboarding view is covering the web view at this point.)
        ROOT.topMenuHidden = NO;

        self.webView.alpha = 1.0f;
    }

    // Don't move this to viewDidLoad - this is because viewDidLoad may only get
    // called very occasionally as app suspend/resume probably doesn't cause
    // viewDidLoad to fire.
    [self downloadAssetsFilesIfNecessary];

    [self performHousekeepingIfNecessary];

    //[self.view randomlyColorSubviews];
}

-(BOOL)shouldShowOnboarding
{
    NSNumber *showOnboarding = [[NSUserDefaults standardUserDefaults] objectForKey:@"ShowOnboarding"];
    return showOnboarding.boolValue;
}

-(void)showOnboarding
{
    OnboardingViewController *onboardingVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"OnboardingViewController"];

    onboardingVC.truePresentingVC = self;
    //[onboardingVC.view.layer removeAllAnimations];
    [self presentViewController:onboardingVC animated:NO completion:^{}];

    [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"ShowOnboarding"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)performHousekeepingIfNecessary
{
    NSDate *lastHousekeepingDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastHousekeepingDate"];
    NSInteger daysSinceLastHouseKeeping = [[NSDate date] daysAfterDate:lastHousekeepingDate];
    NSLog(@"daysSinceLastHouseKeeping = %ld", (long)daysSinceLastHouseKeeping);
    if (daysSinceLastHouseKeeping > 1) {
        NSLog(@"Performing housekeeping...");
        CoreDataHousekeeping *imageHousekeeping = [[CoreDataHousekeeping alloc] init];
        [imageHousekeeping performHouseKeeping];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastHousekeepingDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    if ([self shouldShowOnboarding]) {
        self.webView.alpha = 0.0f;
    }

    [super viewWillAppear:animated];

    self.bottomMenuHidden = ROOT.topMenuHidden;
    self.referencesHidden = YES;

    ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_DEFAULT;
    [ROOT.topMenuViewController updateTOCButtonVisibility];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self tocHideWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
    
    [super viewWillDisappear:animated];
}

#pragma mark Sync config/ios.json if necessary

-(void)downloadAssetsFilesIfNecessary
{
    // Sync config/ios.json at most once per day.
    CGFloat maxAge = 60 * 60 * 24;

    SyncAssetsFileOp *configSyncOp =
    [[SyncAssetsFileOp alloc] initForAssetsFile: ASSETS_FILE_CONFIG
                                         maxAge: maxAge];
    
    SyncAssetsFileOp *cssSyncOp =
    [[SyncAssetsFileOp alloc] initForAssetsFile: ASSETS_FILE_CSS
                                         maxAge: maxAge];
    
    SyncAssetsFileOp *abuseFilterCssSyncOp =
    [[SyncAssetsFileOp alloc] initForAssetsFile: ASSETS_FILE_CSS_ABUSE_FILTER
                                         maxAge: maxAge];
    
    SyncAssetsFileOp *previewCssSyncOp =
    [[SyncAssetsFileOp alloc] initForAssetsFile: ASSETS_FILE_CSS_PREVIEW
                                         maxAge: maxAge];
    
    [[QueuesSingleton sharedInstance].assetsFileSyncQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].assetsFileSyncQ addOperation:configSyncOp];
    [[QueuesSingleton sharedInstance].assetsFileSyncQ addOperation:cssSyncOp];
    [[QueuesSingleton sharedInstance].assetsFileSyncQ addOperation:abuseFilterCssSyncOp];
    [[QueuesSingleton sharedInstance].assetsFileSyncQ addOperation:previewCssSyncOp];
}

#pragma mark Edit section

-(void)showSectionEditor
{
    SectionEditorViewController *sectionEditVC =
    [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"SectionEditorViewController"];

    NSManagedObjectID *articleID =
    [articleDataContext_.mainContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                   domain: [SessionSingleton sharedInstance].currentArticleDomain];
    if (articleID) {
        Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
        
        Section *section =
        (Section *)[articleDataContext_.mainContext getEntityForName: @"Section"
                                                 withPredicateFormat: @"article == %@ AND sectionId == %@", article, @(self.sectionToEditId)];
        
        sectionEditVC.sectionID = section.objectID;
    }

    [ROOT pushViewController:sectionEditVC animated:YES];
}

-(void)searchFieldBecameFirstResponder
{
    [self tocHide];
}

#pragma mark Update constraints

-(void)updateViewConstraints
{
    [self tocConstrainView];
    
    [self constrainBottomMenu];
    
    [super updateViewConstraints];
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
    return (self.webViewRightConstraint.constant == 0) ? NO : YES;
}

-(void)tocHideIfSafeToToggleDuringNextRunLoopWithDuration:(NSNumber *)duration
{
    if(self.unsafeToToggleTOC || !self.tocVC) return;

    // iOS 6 can blank out the web view this isn't scheduled for next run loop.
    [[NSRunLoop currentRunLoop] performSelector: @selector(tocHideWithDuration:)
                                         target: self
                                       argument: duration
                                          order: 0
                                          modes: [NSArray arrayWithObject:@"NSDefaultRunLoopMode"]];
}

-(void)tocHideWithDuration:(NSNumber *)duration
{
    // Ensure one exists to be hidden.
    if (!self.tocVC) return;

    self.unsafeToToggleTOC = YES;
    
    // Save the scroll position; if we're near the end of the page things will
    // get reset correctly when we start to zoom out!
    __block CGPoint origScrollPosition = self.webView.scrollView.contentOffset;

    // Clear alerts
    [self fadeAlert];

    [UIView animateWithDuration: duration.floatValue
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{

                         // If the top menu isn't hidden, reveal the bottom menu.
                         self.bottomMenuHidden = ROOT.topMenuHidden;
                         [self.view setNeedsUpdateConstraints];
                         
                         self.webView.transform = CGAffineTransformIdentity;

                         self.referencesContainerView.transform = CGAffineTransformIdentity;

                         self.bottomBarView.transform = CGAffineTransformIdentity;
                         self.webViewRightConstraint.constant = 0;

                         [self.view layoutIfNeeded];
                     }completion: ^(BOOL done){
                         if(self.tocVC) [self tocViewControllerRemove];
                         self.unsafeToToggleTOC = NO;
                         self.webView.scrollView.contentOffset = origScrollPosition;
                     }];
}

-(void)tocShowIfSafeToToggleDuringNextRunLoopWithDuration:(NSNumber *)duration
{
    if([[SessionSingleton sharedInstance] isCurrentArticleMain]) return;

    if(self.unsafeToToggleTOC || self.tocVC) return;

    // iOS 6 can blank out the web view this isn't scheduled for next run loop.
    [[NSRunLoop currentRunLoop] performSelector: @selector(tocShowWithDuration:)
                                         target: self
                                       argument: duration
                                          order: 0
                                          modes: [NSArray arrayWithObject:@"NSDefaultRunLoopMode"]];
}

-(void)tocShowWithDuration:(NSNumber *)duration
{
    self.unsafeToToggleTOC = YES;

    // Hide any alerts immediately.
    [self hideAlert];

    // Ensure the toc is rebuilt from scratch! Very weird toc scroll view
    // resizing issues (can't scroll up to bottom toc entry sometimes, etc)
    // when choosing different article languages otherwise!
    if(self.tocVC) [self tocViewControllerRemove];
    
    [self tocViewControllerAdd];
    
    [self.tocVC centerCellForWebViewTopMostSectionAnimated:NO];

    CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
    CGAffineTransform xf = CGAffineTransformMakeScale(webViewScale, webViewScale);

    [UIView animateWithDuration: duration.floatValue
                          delay: 0.0f
                        options: 0 // UIViewAnimationOptionBeginFromCurrentState <--Don't do this, can cause toc to jump as it appears (if top/bottom menus visibility changes)
                     animations: ^{

                         self.bottomMenuHidden = YES;
                         self.referencesHidden = YES;
                         [self.view setNeedsUpdateConstraints];
                         self.webView.transform = xf;
                         self.referencesContainerView.transform = xf;
                         self.bottomBarView.transform = xf;
                         self.webViewRightConstraint.constant = [self tocGetWidthForWebViewScale:webViewScale];
                         [self.view layoutIfNeeded];
                     }completion: ^(BOOL done){
                         [self.view setNeedsUpdateConstraints];
                         self.unsafeToToggleTOC = NO;
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

    // This ensures the toc cells assume the proper height for how many lines of text they're displaying before
    // toc show animation. Otherwise they grow to their height as part of the show animation.
    [self.tocVC.view layoutIfNeeded];

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
    [self tocHideIfSafeToToggleDuringNextRunLoopWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

-(void)tocShow
{
    [self tocShowIfSafeToToggleDuringNextRunLoopWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

-(void)tocToggle
{
    // Clear alerts
    [self fadeAlert];

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
    
    // Device rtl value is checked since this is what would cause the other constraints to flip.
    BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];

    [self tocSetupSwipeGestureRecognizer: self.tocSwipeLeftRecognizer
                            forDirection: (isRTL ? UISwipeGestureRecognizerDirectionRight : UISwipeGestureRecognizerDirectionLeft)];

    [self tocSetupSwipeGestureRecognizer: self.tocSwipeRightRecognizer
                            forDirection: (isRTL ? UISwipeGestureRecognizerDirectionLeft : UISwipeGestureRecognizerDirectionRight)];
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
    NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;
    if (!currentArticleTitle || (currentArticleTitle.length == 0)) return;

    if (recognizer.state == UIGestureRecognizerStateEnded){
        if (self.referencesHidden) {
            [self tocShow];
        }
    }
}

-(void)tocSwipeRightHandler:(UISwipeGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded){
        [self tocHide];
    }
}

-(CGFloat)tocGetWebViewScaleWhenTOCVisible
{
    CGFloat scale = 1.0;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        scale = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.6f : 0.7f);
    }else{
        scale = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.42f : 0.55f);
    }

    // Adjust scale so it won't result in fractional pixel width when applied to web view width.
    // This prevents the web view from jumping a bit w/long pages.
    NSInteger i = (NSInteger)self.view.frame.size.width * scale;
    CGFloat cleanScale = (i / self.view.frame.size.width);
    
    return cleanScale;
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
                                       attribute: NSLayoutAttributeLeading      // "Leading" for rtl langs.
                                       relatedBy: NSLayoutRelationEqual
                                          toItem: self.webView
                                       attribute: NSLayoutAttributeTrailing     // "Trailing" for rtl langs.
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

-(void)tocScrollWebViewToSectionWithElementId: (NSString *)elementId
                                     duration: (CGFloat)duration
                                  thenHideTOC: (BOOL)hideTOC
{
    CGRect r = [self.webView getWebViewRectForHtmlElementWithId:elementId];
    if (CGRectIsNull(r)) return;
    
    CGPoint point = r.origin;

    // Leave x unchanged.
    point.x = self.webView.scrollView.contentOffset.x;
    
    // Scroll the section up just a tad more so the top of section div is just above top of web view.
    // This ensures the section that was scrolled to is considered the "current" section. (This is
    // because the current section is the one intersecting the top of the screen.)

    point.y += 2;
    
    [self tocScrollWebViewToPoint:point
                         duration:duration
                      thenHideTOC:hideTOC];
}

-(void)tocScrollWebViewToPoint: (CGPoint)point
                      duration: (CGFloat)duration
                   thenHideTOC: (BOOL)hideTOC
{
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
        if (self.jumpToFragment) {
            // See if this works
            [self.bridge sendMessage:@"scrollToFragment"
                         withPayload:@{@"hash": self.jumpToFragment}];
        }
    } else if (
        (object == self.bottomBarView)
        &&
        ([keyPath isEqual:@"bounds"])
        ) {
            [self updateWebViewContentAndScrollInsets];
    }
}

#pragma mark Dealloc

-(void)dealloc
{
    [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize"];
    [self.bottomBarView removeObserver:self forKeyPath:@"bounds"];

    // This needs to be in dealloc.
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"LanguageItemSelected"
                                                  object: nil];
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
    self.bridge = [[CommunicationBridge alloc] initWithWebView:self.webView htmlFileName:@"index.html"];
    [self.bridge addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
        //NSLog(@"QQQ HEY DOMLoaded!");
    }];

    __weak WebViewController *weakSelf = self;
    [self.bridge addListener:@"linkClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSString *href = payload[@"href"];

        if([weakSelf tocDrawerIsOpen]){
            [weakSelf tocHide];
            return;
        }

        if(!weakSelf.referencesHidden) [weakSelf referencesHide];
        
        // @todo merge this link title extraction into MWSite
        if ([href hasPrefix:@"/wiki/"]) {

            // Ensure the menu is visible when navigating to new page.
            [weakSelf animateTopAndBottomMenuReveal];
        
            NSString *encodedTitle = [href substringWithRange:NSMakeRange(6, href.length - 6)];
            NSString *title = [encodedTitle stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            MWPageTitle *pageTitle = [MWPageTitle titleWithString:title];

            [weakSelf navigateToPage: pageTitle
                              domain: [SessionSingleton sharedInstance].currentArticleDomain
                     discoveryMethod: DISCOVERY_METHOD_LINK
                   invalidatingCache: NO];
        } else if ([href hasPrefix:@"http:"] || [href hasPrefix:@"https:"] || [href hasPrefix:@"//"]) {
            // A standard external link, either explicitly http(s) or left protocol-relative on web meaning http(s)
            if ([href hasPrefix:@"//"]) {
                // Expand protocol-relative link to https -- secure by default!
                href = [@"https:" stringByAppendingString:href];
            }
            
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

        if([weakSelf tocDrawerIsOpen]){
            [weakSelf tocHide];
            return;
        }
        
        if (weakSelf.editable) {
            weakSelf.sectionToEditId = [payload[@"sectionId"] integerValue];
            [weakSelf showSectionEditor];
        } else {
            ProtectedEditAttemptFunnel *funnel = [[ProtectedEditAttemptFunnel alloc] init];
            [funnel logProtectionStatus:weakSelf.protectionStatus];
            [weakSelf showProtectedDialog];
        }
    }];
    
    [self.bridge addListener:@"langClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        if([weakSelf tocDrawerIsOpen]){
            [weakSelf tocHide];
            return;
        }

        NSLog(@"Language button pushed");
        [weakSelf languageButtonPushed];
    }];
    
    [self.bridge addListener:@"historyClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        if([weakSelf tocDrawerIsOpen]){
            [weakSelf tocHide];
            return;
        }

        [weakSelf historyButtonPushed];
    }];
    
    [self.bridge addListener:@"nonAnchorTouchEndedWithoutDragging" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSLog(@"nonAnchorTouchEndedWithoutDragging = %@", payload);

        [weakSelf animateTopAndBottomMenuReveal];

        // nonAnchorTouchEndedWithoutDragging is used so TOC may be hidden if user tapped, but did *not* drag.
        // Used because UIWebView is difficult to attach one-finger touch events to.
        [weakSelf tocHide];

        [weakSelf referencesHide];
    }];
    
    [self.bridge addListener:@"referenceClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {

        if([weakSelf tocDrawerIsOpen]){
            [weakSelf tocHide];
            return;
        }

        //NSLog(@"referenceClicked: %@", payload);
        [weakSelf referencesShow:payload];
        
    }];

    self.unsafeToScroll = NO;
    self.scrollOffset = CGPointZero;
}

#pragma mark History

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Ensure the web VC is the top VC.
    [ROOT popToViewController:self animated:YES];

    [self fadeAlert];
}

#pragma Saved Pages

-(void)saveCurrentPage
{
    [self showAlert:MWLocalizedString(@"share-menu-page-saved", nil)];
    [self fadeAlert];

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
    // Don't record scroll position of "main" pages.
    if ([[SessionSingleton sharedInstance] isCurrentArticleMain]) return;

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
    CGRect r = [self.webView getScreenRectForHtmlElementWithId:@"section_heading_and_content_block_1"];
    NSLog(@"r = %@", NSStringFromCGRect(r));

    CGRect r2 = [self.webView getWebViewRectForHtmlElementWithId:@"section_heading_and_content_block_1"];
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
    
    [self adjustTopAndBottomMenuVisibilityOnScroll];

    [super scrollViewDidScroll:scrollView];
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

#pragma mark Menus auto show-hide on scroll / reveal on tap

-(void)adjustTopAndBottomMenuVisibilityOnScroll
{
    // This method causes the menus to hide when user scrolls down and show when they scroll up.
    if (self.webView.scrollView.isDragging && ![self tocDrawerIsOpen]){
        CGFloat distanceScrolled = scrollViewDragBeganVerticalOffset_ - self.webView.scrollView.contentOffset.y;
        CGFloat minPixelsScrolled = 20;
        
        // Reveal menus if scroll velocity is a bit fast. Point is to avoid showing the menu
        // if the user is *slowly* scrolling. This is how Safari seems to handle things.
        CGPoint scrollVelocity = [self.webView.scrollView.panGestureRecognizer velocityInView:self.view];
        if (distanceScrolled > 0) {
            // When pulling down let things scroll a bit faster before menus reveal is triggered.
            if (scrollVelocity.y < 350.0f) return;
        }else{
            // When pushing up set a lower scroll velocity threshold to hide menus.
            if (scrollVelocity.y > -250.0f) return;
        }
        
        if (fabsf(distanceScrolled) < minPixelsScrolled) return;
        [ROOT animateTopAndBottomMenuHidden:((distanceScrolled > 0) ? NO : YES)];

        [self referencesHide];
    }
}

-(void)animateTopAndBottomMenuReveal
{
    // Toggle the menus closed on tap (only if they were showing).
    if (!self.tocVC) {
        if (ROOT.topMenuViewController.navBarMode != NAVBAR_MODE_SEARCH) {
            if (![self tocDrawerIsOpen]){
                [ROOT animateTopAndBottomMenuHidden:NO];
            }
        }
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    [self referencesHide];

    // Called when the title bar is tapped.
    [self animateTopAndBottomMenuReveal];
    return YES;
}

#pragma mark Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

    /*
    OnboardingViewController *onboardingVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"OnboardingViewController"];
    [self presentViewController:onboardingVC animated:YES completion:^{}];
    */

    /*
    AccountCreationViewController *createAcctVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"AccountCreationViewController"];

    [ROOT pushViewController:createAcctVC animated:YES];
    */
    
    //CoreDataHousekeeping *imageHousekeeping = [[CoreDataHousekeeping alloc] init];
    //[imageHousekeeping performHouseKeeping];
    
    // Do not remove the following commented toggle. It's for testing W0 stuff.
    //[[SessionSingleton sharedInstance].zeroConfigState toggleFakeZeroOn];

    //[self toggleImageSheet];

    //ReferencesVC *referencesVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"ReferencesVC"];
    //[self presentViewController:referencesVC animated:YES completion:^{}];
}

-(void)toggleImageSheet
{
    // Quick hack for confirming images for article have routed properly to core data store.
    // To do this for real, probably need to make separate view controller - could still present
    // images using save autolayout stacking as "topActionSheetShowWithViews", but would need to
    // determine which UIImageViews were scrolled offscreen and nil their image property out
    // until they're not offscreen. Could do separate UIImageView class to make this easier - it
    // would have a property with the image's core data ImageData NSManagedObjectID. That way
    // it could simply re-retrieve its image data whenever it needed to.
    static BOOL showImageSheet = NO;
    showImageSheet = !showImageSheet;
    
    if(showImageSheet){
        NSManagedObjectContext *ctx = articleDataContext_.mainContext;
        [ctx performBlockAndWait:^(){
            NSManagedObjectID *articleID =
            [ctx getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                               domain: [SessionSingleton sharedInstance].currentArticleDomain];
            Article *article = (Article *)[ctx objectWithID:articleID];
            NSArray *sectionImages = [article getSectionImagesUsingContext:ctx];
            NSMutableArray *views = @[].mutableCopy;
            for (SectionImage *sectionImage in sectionImages) {
                Section *section = sectionImage.section;
                NSString *title = (section.title.length > 0) ? section.title : [SessionSingleton sharedInstance].currentArticleTitle;
                //NSLog(@"\n\n\nsection image = %@ \n\tsection = %@ \n\tindex in section = %@ \n\timage size = %@", sectionImage.image.fileName, sectionTitle, sectionImage.index, sectionImage.image.dataSize);
                if(sectionImage.index.integerValue == 0){
                    PaddedLabel *label = [[PaddedLabel alloc] init];
                    label.padding = UIEdgeInsetsMake(20, 20, 10, 20);
                    label.numberOfLines = 0;
                    label.textColor = [UIColor darkGrayColor];
                    label.lineBreakMode = NSLineBreakByWordWrapping;
                    label.font = [UIFont systemFontOfSize:30];
                    label.textAlignment = NSTextAlignmentCenter;
                    title = [title getStringWithoutHTML];
                    label.text = title;
                    [views addObject:label];
                }
                UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage alloc] initWithData:sectionImage.image.imageData.data]];
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                [views addObject:imageView];
                UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 5)];
                [views addObject:spacerView];
            }
            [NAV topActionSheetShowWithViews:views orientation:TABULAR_SCROLLVIEW_LAYOUT_HORIZONTAL];
        }];
    }else{
        [NAV topActionSheetHide];
    }
}

-(void)updateHistoryDateVisitedForArticleBeingNavigatedFrom
{
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *articleID =
        [articleDataContext_.mainContext getArticleIDForTitle: self.currentTitle
                                                       domain: self.currentDomain];
        if (articleID) {
            Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
            if (article) {
                if (article.history.count > 0) { // There should only be a single history item.
                    History *history = [article.history anyObject];
                    history.dateVisited = [NSDate date];
                    NSError *error = nil;
                    [articleDataContext_.mainContext save:&error];
                    if (error) {
                        NSLog(@"error = %@", error);
                    }
                }
            }
        }
    }];
}

#pragma mark Article loading ops

- (void)navigateToPage: (MWPageTitle *)title
                domain: (NSString *)domain
       discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod
     invalidatingCache: (BOOL)invalidateCache
{
    NSString *cleanTitle = title.text;
    
    // Don't try to load nothing. Core data takes exception with such nonsense.
    if (cleanTitle == nil) return;
    if (cleanTitle.length == 0) return;
    
    [self hideKeyboard];
    
    // Show loading message
    [self showAlert:MWLocalizedString(@"search-loading-section-zero", nil)];

    if (invalidateCache) [self invalidateCacheForPageTitle:title domain:domain];
    
    self.jumpToFragment = title.fragment;

    // Update the history dateVisited timestamp of the article *presently shown* by the webView
    // only if the article to be loaded was NOT loaded via back or forward buttons. The article
    // being *navigated to* has its history dateVisited updated later in this method.
    if (discoveryMethod != DISCOVERY_METHOD_BACKFORWARD) {
        [self updateHistoryDateVisitedForArticleBeingNavigatedFrom];
    }
    self.currentTitle = title.text;
    self.currentDomain = domain;
    
    [self retrieveArticleForPageTitle: title
                               domain: domain
                      discoveryMethod: [NAV getStringForDiscoveryMethod:discoveryMethod]];

    // Reset the search field to its placeholder text after 5 seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
        if (!textFieldContainer.textField.isFirstResponder) textFieldContainer.textField.text = @"";
    });
}

- (void)invalidateCacheForPageTitle: (MWPageTitle *)pageTitle
                             domain: (NSString *)domain
{
    // Mark article for refreshing so its core data records will be reloaded.
    // (Needs to be done on worker context as worker context changes bubble up through
    // main context too - so web view controller accessing main context will see changes.)
    NSManagedObjectID *articleID =
    [articleDataContext_.mainContext getArticleIDForTitle: pageTitle.prefixedText
                                                   domain: domain];
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
    }
}

-(void)reloadCurrentArticleInvalidatingCache:(BOOL)invalidateCache
{
    MWPageTitle *title = [MWPageTitle titleWithString:[SessionSingleton sharedInstance].currentArticleTitle];
    [self navigateToPage: title
                  domain: [SessionSingleton sharedInstance].currentArticleDomain
         discoveryMethod: DISCOVERY_METHOD_SEARCH
       invalidatingCache: invalidateCache];
}

- (void)retrieveArticleForPageTitle: (MWPageTitle *)pageTitle
                             domain: (NSString *)domain
                    discoveryMethod: (NSString *)discoveryMethod
{
    // Cancel any in-progress article retrieval operations
    [[QueuesSingleton sharedInstance].articleRetrievalQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].searchQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].thumbnailQ cancelAllOperations];

    __block NSManagedObjectID *articleID =
    [articleDataContext_.mainContext getArticleIDForTitle: pageTitle.prefixedText
                                                   domain: domain];
    BOOL needsRefresh = NO;

    if (articleID) {
        Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];

        // Update the history dateVisited timestamp of the article to be visited only
        // if the article was NOT loaded via back or forward buttons.
        if (![discoveryMethod isEqualToString:@"backforward"]) {
            if (article.history.count > 0) { // There should only be a single history item.
                History *history = [article.history anyObject];
                history.dateVisited = [NSDate date];
            }
        }
        
        // If article with sections just show them (unless needsRefresh is YES)
        if (article.section.count > 0 && !article.needsRefresh.boolValue) {
            [self displayArticle:articleID mode:DISPLAY_ALL_SECTIONS];
            [self showAlert:MWLocalizedString(@"search-loading-article-loaded", nil)];
            [self fadeAlert];
            return;
        }
        needsRefresh = article.needsRefresh.boolValue;
    }

    // Retrieve remaining sections op (dependent on first section op)
    DownloadSectionsOp *remainingSectionsOp =
    [[DownloadSectionsOp alloc] initForPageTitle: pageTitle.prefixedText
                                          domain: [SessionSingleton sharedInstance].currentArticleDomain
                                 leadSectionOnly: NO
                                 completionBlock: ^(NSDictionary *results){
        
        // Just in case the article wasn't created during the "parent" operation.
        if (!articleID) return;

        [articleDataContext_.workerContext performBlockAndWait:^(){
            // The completion block happens on non-main thread, so must get article from articleID again.
            // Because "you can only use a context on a thread when the context was created on that thread"
            // this must happen on workerContext as well (see: http://stackoverflow.com/a/6356201/135557)
            Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];

            //Non-lead sections have been retreived so set needsRefresh to NO.
            article.needsRefresh = @NO;

            NSArray *sectionsRetrieved = results[@"sections"];

            for (NSDictionary *section in sectionsRetrieved) {
                if (![section[@"id"] isEqual: @0]) {
                                    
                    // Add sections for article
                    Section *thisSection = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:articleDataContext_.workerContext];

                    // Section index is a string because transclusion sections indexes will start with "T-".
                    if ([section[@"index"] isKindOfClass:[NSString class]]) {
                        thisSection.index = section[@"index"];
                    }

                    thisSection.title = section[@"line"];

                    if ([section[@"level"] isKindOfClass:[NSString class]]) {
                        thisSection.level = section[@"level"];
                    }

                    // Section number, from the api, can be 3.5.2 etc, so it's a string.
                    if ([section[@"number"] isKindOfClass:[NSString class]]) {
                        thisSection.number = section[@"number"];
                    }

                    if (section[@"fromtitle"]) {
                        thisSection.fromTitle = section[@"fromtitle"];
                    }

                    thisSection.sectionId = section[@"id"];

                    thisSection.html = section[@"text"];
                    thisSection.tocLevel = section[@"toclevel"];
                    thisSection.dateRetrieved = [NSDate date];
                    thisSection.anchor = (section[@"anchor"]) ? section[@"anchor"] : @"";

                    [article addSectionObject:thisSection];

                    [thisSection createImageRecordsForHtmlOnContext:articleDataContext_.workerContext];
                }
            }

            NSError *error = nil;
            [articleDataContext_.workerContext save:&error];
        }];
        
        [self displayArticle:articleID mode:DISPLAY_APPEND_NON_LEAD_SECTIONS];
        [self showAlert:MWLocalizedString(@"search-loading-article-loaded", nil)];
        [self fadeAlert];

    } cancelledBlock:^(NSError *error){
        [self fadeAlert];
    } errorBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
    }];

    remainingSectionsOp.delegate = self;


    // Retrieve first section op
    DownloadSectionsOp *firstSectionOp =
    [[DownloadSectionsOp alloc] initForPageTitle: pageTitle.prefixedText
                                          domain: [SessionSingleton sharedInstance].currentArticleDomain
                                 leadSectionOnly: YES
                                 completionBlock: ^(NSDictionary *dataRetrieved){


        NSString *redirectedTitle = [dataRetrieved[@"redirected"] copy];

        // Redirect if the pageTitle which triggered this call to "retrieveArticleForPageTitle"
        // differs from titleReflectingAnyRedirects.
        if (redirectedTitle.length > 0) {
            MWPageTitle *newTitle = [MWPageTitle titleWithString:redirectedTitle];
            [self retrieveArticleForPageTitle: newTitle
                                       domain: domain
                              discoveryMethod: discoveryMethod];
            return;
        }

        [articleDataContext_.workerContext performBlockAndWait:^(){
            Article *article = nil;

            if (!articleID) {
                article = [NSEntityDescription
                    insertNewObjectForEntityForName:@"Article"
                    inManagedObjectContext:articleDataContext_.workerContext
                ];
                article.title = pageTitle.prefixedText;
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
            article.articleId = dataRetrieved[@"articleId"];
            article.editable = dataRetrieved[@"editable"];
            article.protectionStatus = dataRetrieved[@"protectionStatus"];


            // Note: Because "retrieveArticleForPageTitle" recurses with the redirected-to title if
            // the lead section op determines a redirect occurred, the "redirected" value below will
            // probably never be set.
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
            
            NSArray *result = [ROOT.topMenuViewController.currentSearchResultsOrdered filteredArrayUsingPredicate:
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
            // Section index is a string because transclusion sections indexes will start with "T-"
            section0.index = @"0";
            section0.level = @"0";
            section0.number = @"0";
            section0.sectionId = @0;
            section0.title = @"";
            section0.dateRetrieved = [NSDate date];
            section0.html = section0HTML;
            section0.anchor = @"";
            
            [article addSectionObject:section0];

            [section0 createImageRecordsForHtmlOnContext:articleDataContext_.workerContext];

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
        }];

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
        
        // @TODO potentially do this in the difFailWithError in MWNetworkOp
        // It seems safe enough, but we didn't want to cause any sort of memory leak
        if (error.domain == NSStreamSocketSSLErrorDomain ||
            (error.domain == NSURLErrorDomain &&
             (error.code == NSURLErrorSecureConnectionFailed ||
              error.code == NSURLErrorServerCertificateHasBadDate ||
              error.code == NSURLErrorServerCertificateUntrusted ||
              error.code == NSURLErrorServerCertificateHasUnknownRoot ||
              error.code == NSURLErrorServerCertificateNotYetValid)
             )
            ) {
            [SessionSingleton sharedInstance].fallback = true;
        }
    }];

    firstSectionOp.delegate = self;
    
    
    // Retrieval of remaining sections depends on retrieving first section
    [remainingSectionsOp addDependency:firstSectionOp];
    
    [[QueuesSingleton sharedInstance].articleRetrievalQ addOperation:remainingSectionsOp];
    [[QueuesSingleton sharedInstance].articleRetrievalQ addOperation:firstSectionOp];
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

#pragma mark Display article from core data

- (void)displayArticle:(NSManagedObjectID *)articleID mode:(DisplayMode)mode
{
    // Get sorted sections for this article (sorts the article.section NSSet into sortedSections)
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sectionId" ascending:YES];

    Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];

    if (!article) return;
    [SessionSingleton sharedInstance].currentArticleTitle = article.title;
    [SessionSingleton sharedInstance].currentArticleDomain = article.domain;
    MWLanguageInfo *languageInfo = [MWLanguageInfo languageInfoForCode:article.domain];
    NSString *uidir = ([WikipediaAppUtils isDeviceLanguageRTL] ? @"rtl" : @"ltr");

    NSNumber *langCount = article.languagecount;
    NSDate *lastModified = article.lastmodified;
    NSString *lastModifiedBy = article.lastmodifiedby;
    self.editable = article.editableBool;
    self.protectionStatus = article.protectionStatus;
    
    [self.bottomMenuViewController updateBottomBarButtonsEnabledState];

    [ROOT.topMenuViewController updateTOCButtonVisibility];

    NSArray *sortedSections = [article.section sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSMutableArray *sectionTextArray = [@[] mutableCopy];
    
    for (Section *section in sortedSections) {
        if (mode == DISPLAY_APPEND_NON_LEAD_SECTIONS) {
            if ([section isLeadSection]) continue;
        }
        if (section.html){
            // Structural html added around section html just before display.
            NSString *sectionHTMLWithID = [section displayHTML];

            [sectionTextArray addObject:sectionHTMLWithID];
        }
        if (mode == DISPLAY_LEAD_SECTION) break;
    }
    
    // If article has no thumbnailImage, use the first section image instead.
    // Actually sets article.thumbnailImage to point to the image record of the first section
    // image. That way, if the housekeeping code removes all section images, it won't remove this
    // particular one because it checks to see if an article is referencing an image before it
    // removes them.
    [article ifNoThumbnailUseFirstSectionImageAsThumbnailUsingContext:articleDataContext_.mainContext];

    // Pull the scroll offset out so the article object doesn't have to be passed into the block below.
    CGPoint scrollOffset = CGPointMake(article.lastScrollX.floatValue, article.lastScrollY.floatValue);
    NSString *jumpToFragment = self.jumpToFragment;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        if (mode != DISPLAY_APPEND_NON_LEAD_SECTIONS) {
            // See comments inside resetBridge.
            [self resetBridge];
        }
        
        if (jumpToFragment == nil) {
            self.scrollOffset = scrollOffset;
        }


        if ((mode != DISPLAY_LEAD_SECTION) && ![[SessionSingleton sharedInstance] isCurrentArticleMain]) {
            [sectionTextArray addObject: [self renderFooterDivider]];
            [sectionTextArray addObject: [self renderLastModified:lastModified by:lastModifiedBy]];
            [sectionTextArray addObject: [self renderLanguageButtonForCount: langCount.integerValue]];
            [sectionTextArray addObject: [self renderLicenseFooter]];
        }

        
        // Join article sections text
        NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
        NSString *htmlStr = [sectionTextArray componentsJoinedByString:joint];
        
        // NSLog(@"languageInfo = %@", languageInfo.code);
        // Display all sections
        [self.bridge sendMessage: @"setLanguage"
                     withPayload: @{
                                   @"lang": languageInfo.code,
                                   @"dir": languageInfo.dir,
                                   @"uidir": uidir
                                   }];
        
        [self.bridge sendMessage:@"append" withPayload:@{@"html": htmlStr}];
        // Note: we set the scroll position later, after the size has been calculated
        
        if (!self.editable) {
            [self.bridge sendMessage:@"setPageProtected" withPayload:@{}];
        }
        
        if ([self tocDrawerIsOpen]) {
            // Drawer is already open, so just refresh the toc quickly w/o animation.
            // Make sure "tocShowWithDuration:" is allowed to happen even if the TOC
            // is already onscreen or non-lead sections won't appear in the TOC when
            // they've been retrieved if the TOC is open.
            [self tocShowWithDuration:@0.0f];
        }
    }];
}

-(NSString *)renderFooterDivider
{
    NSString *langCode = [[NSLocale preferredLanguages] objectAtIndex:0];
    MWLanguageInfo *lang = [MWLanguageInfo languageInfoForCode:langCode];
    NSString *dir = lang.dir;
    return [NSString stringWithFormat:@"<hr class=\"mw-footer-divider\" dir=\"%@\">", dir];
}

-(NSString *)renderLanguageButtonForCount:(NSInteger)count
{
    if (count > 0) {
        NSString *langCode = [[NSLocale preferredLanguages] objectAtIndex:0];
        MWLanguageInfo *lang = [MWLanguageInfo languageInfoForCode:langCode];
        NSString *dir = lang.dir;

        NSString *icon = WIKIGLYPH_TRANSLATE;
        NSString *text = [NSString localizedStringWithFormat:MWLocalizedString(@"language-button-text", nil), (int)count];
        
        return [NSString stringWithFormat:@"<button dir=\"%@\" class=\"mw-language-button mw-footer-button\">"
                                          @"<div>"
                                          @"<span><span class=\"mw-footer-icon\">%@</span></span>"
                                          @"<span>%@</span>"
                                          @"</div>"
                                          @"</button>", dir, icon, text];
    } else {
        return @"";
    }
}

-(NSString *)renderLastModified:(NSDate *)date by:(NSString *)username
{
    NSString *langCode = [[NSLocale preferredLanguages] objectAtIndex:0];
    MWLanguageInfo *lang = [MWLanguageInfo languageInfoForCode:langCode];
    NSString *dir = lang.dir;
    NSString *icon = WIKIGLYPH_PENCIL;

    NSString *ts = [WikipediaAppUtils relativeTimestamp:date];
    NSString *recent = (fabs([date timeIntervalSinceNow]) < 60*60*24) ? @"recent" : @"";
    NSString *lm;
    if (username && ![username isEqualToString:@""]) {
        lm = [[MWLocalizedString(@"lastmodified-by-user", nil)
               stringByReplacingOccurrencesOfString:@"$1" withString:ts]
                stringByReplacingOccurrencesOfString:@"$2" withString:username];
    } else {
        lm = [MWLocalizedString(@"lastmodified-by-anon", nil)
              stringByReplacingOccurrencesOfString:@"$1" withString:ts];
    }

    return [NSString stringWithFormat:@"<button dir=\"%@\" class=\"mw-last-modified mw-footer-button %@\">"
            @"<div>"
            @"<span><span class=\"mw-footer-icon\">%@</span></span>"
            @"<span>%@</span>"
            @"</div>"
            @"</button>", dir, recent, icon, lm];
}

-(NSString *)renderLicenseFooter
{
    NSString *langCode = [[NSLocale preferredLanguages] objectAtIndex:0];
    MWLanguageInfo *lang = [MWLanguageInfo languageInfoForCode:langCode];
    NSString *dir = lang.dir;
    
    NSString *licenseName = MWLocalizedString(@"license-footer-name", nil);
    NSString *licenseLink = [NSString stringWithFormat:@"<a href=\"https://en.m.wikipedia.org/wiki/Wikipedia:Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License\">%@</a>", licenseName];
    NSString *licenseText = [MWLocalizedString(@"license-footer-text", nil) stringByReplacingOccurrencesOfString:@"$1" withString:licenseLink];
    
    return [NSString stringWithFormat:@"<div dir=\"%@\" class=\"mw-license-footer\">%@</div>", dir, licenseText];
}

#pragma mark Scroll to last section after rotate

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    NSString *js = @"(function() {"
                   @"    _topElement = document.elementFromPoint( window.innerWidth / 2, 0 );"
                   @"    if (_topElement) {"
                   @"        var rect = _topElement.getBoundingClientRect();"
                   @"        return rect.top / rect.height;"
                   @"    } else {"
                   @"        return 0;"
                   @"    }"
                   @"})()";
    float relativeScrollOffset = [[self.webView stringByEvaluatingJavaScriptFromString:js] floatValue];
    self.relativeScrollOffsetBeforeRotate = relativeScrollOffset;

    [self tocHideWithDuration:@0.0f];
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self scrollToElementOnScreenBeforeRotate];
    
    [self updateWebViewContentAndScrollInsets];
}

-(void)scrollToElementOnScreenBeforeRotate
{
    NSString *js = @"(function() {"
                   @"    if (_topElement) {"
                   @"        var rect = _topElement.getBoundingClientRect();"
                   @"        return (window.scrollY + rect.top) - (%f * rect.height);"
                   @"    } else {"
                   @"        return 0;"
                   @"    }"
                   @"})()";
    NSString *js2 = [NSString stringWithFormat:js, self.relativeScrollOffsetBeforeRotate, self.relativeScrollOffsetBeforeRotate];
    int finalScrollOffset = [[self.webView stringByEvaluatingJavaScriptFromString:js2] intValue];

    CGPoint point = CGPointMake(0, finalScrollOffset);

    [self tocScrollWebViewToPoint:point
                          duration:0
                       thenHideTOC:NO];
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
         completionBlock: ^(NSString *title) {
         
             if (title) {
                 dispatch_async(dispatch_get_main_queue(), ^(){
                 
                     TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
                     textFieldContainer.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text-zero", nil);

                     self.zeroStatusLabel.text = title;
                     self.zeroStatusLabel.padding = UIEdgeInsetsMake(3, 10, 3, 10);
                     self.zeroStatusLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.93];

                     [self showAlert:title];
                     [NAV promptFirstTimeZeroOnWithTitleIfAppropriate:title];
                 });
             }
         } cancelledBlock:^(NSError *errorCancel) {
             NSLog(@"error w0 cancel");
         } errorBlock:^(NSError *errorError) {
             NSLog(@"error w0 error");
         }];

        [[QueuesSingleton sharedInstance].zeroRatedMessageStringQ addOperation:zeroMessageRetrievalOp];
        
    } else {
    
        TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
        textFieldContainer.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text", nil);
        NSString *warnVerbiage = MWLocalizedString(@"zero-charged-verbiage", nil);

        self.zeroStatusLabel.text = warnVerbiage;
        self.zeroStatusLabel.backgroundColor = [UIColor redColor];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.zeroStatusLabel.text = @"";
            self.zeroStatusLabel.padding = UIEdgeInsetsZero;
        });

        [self showAlert:warnVerbiage];
        [NAV promptZeroOff];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (1 == buttonIndex) {
        NSURL *url = [NSURL URLWithString:self.externalUrl];
        [[UIApplication sharedApplication] openURL:url];
    }
}

-(UIScrollView *)refreshScrollView
{
    return self.webView.scrollView;
}

-(NSString *)refreshPromptString
{
    return MWLocalizedString(@"article-pull-to-refresh-prompt", nil);
}

-(NSString *)refreshRunningString
{
    return MWLocalizedString(@"article-pull-to-refresh-is-refreshing", nil);
}

-(void)refreshWasPulled
{
    [self reloadCurrentArticleInvalidatingCache:YES];
}

-(BOOL)refreshShouldShow
{
    NSString *title = [SessionSingleton sharedInstance].currentArticleTitle;
    
    return
    ([QueuesSingleton sharedInstance].articleRetrievalQ.operationCount == 0)
    &&
    (![self tocDrawerIsOpen])
    &&
    (title && (title.length > 0))
    ;
}

#pragma mark Data migration

- (void)migrateDataIfNecessary
{
    DataMigrator *dataMigrator = [[DataMigrator alloc] init];
    if ([dataMigrator hasData]) {
        NSLog(@"Old data to migrate found!");
        NSArray *titles = [dataMigrator extractSavedPages];
        ArticleImporter *importer = [[ArticleImporter alloc] init];
        
        for (NSDictionary *item in titles) {
            NSLog(@"Will import saved page: %@ %@", item[@"lang"], item[@"title"]);
        }
        
        [importer importArticles:titles];
        
        [dataMigrator removeOldData];
    } else {
        NSLog(@"No old data to migrate.");
    }

}

#pragma mark Bottom menu bar

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString: @"BottomMenuViewController_embed2"]) {
		self.bottomMenuViewController = (BottomMenuViewController *) [segue destinationViewController];
	}
}

-(void)setBottomMenuHidden:(BOOL)bottomMenuHidden
{
    if (self.bottomMenuHidden == bottomMenuHidden) return;

    _bottomMenuHidden = bottomMenuHidden;

    // Fade out the top menu when it is hidden.
    CGFloat alpha = bottomMenuHidden ? 0.0 : 1.0;
    
    self.bottomBarView.alpha = alpha;

    [self updateWebViewContentAndScrollInsets];
}

-(void)constrainBottomMenu
{
    // If visible, constrain bottom of bottomNavBar to bottom of superview.
    // If hidden, constrain top of bottomNavBar to bottom of superview.

    if (self.bottomBarViewBottomConstraint) {
        [self.view removeConstraint:self.bottomBarViewBottomConstraint];
    }

    self.bottomBarViewBottomConstraint =
    [NSLayoutConstraint constraintWithItem: self.bottomBarView
                                      attribute: ((self.bottomMenuHidden) ? NSLayoutAttributeTop : NSLayoutAttributeBottom)
                                      relatedBy: NSLayoutRelationEqual
                                         toItem: self.view
                                      attribute: NSLayoutAttributeBottom
                                     multiplier: 1.0
                                       constant: 0];

    [self.view addConstraint:self.bottomBarViewBottomConstraint];
}

-(void)updateWebViewContentAndScrollInsets
{
    // Ensure web view can be scrolled to bottom and that scroll indicator doesn't underlap
    // bottom menu.
    CGFloat bottomBarHeight = self.bottomBarView.bounds.size.height;
    if(self.bottomBarView.alpha == 0) bottomBarHeight = 0;
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, bottomBarHeight, 0);
    self.webView.scrollView.contentInset = insets;
    self.webView.scrollView.scrollIndicatorInsets = insets;
}

#pragma mark Languages

-(void)languageButtonPushed
{
    [self performModalSequeWithID: @"modal_segue_show_languages"
                  transitionStyle: UIModalTransitionStyleCoverVertical
                            block: ^(LanguagesViewController *languagesVC){
                                languagesVC.downloadLanguagesForCurrentArticle = YES;
                                languagesVC.invokingVC = self;
                            }];
}

-(void)historyButtonPushed
{
    [self performModalSequeWithID: @"modal_segue_show_page_history"
                  transitionStyle: UIModalTransitionStyleCoverVertical
                            block: nil];
}

- (void)languageItemSelectedNotification:(NSNotification *)notification
{
    // Ensure action is only taken if the web view controller presented the lang picker.
    LanguagesViewController *languagesVC = notification.object;
    if (languagesVC.invokingVC != self) return;

    NSDictionary *selectedLangInfo = [notification userInfo];

    MWPageTitle *pageTitle = [MWPageTitle titleWithString:selectedLangInfo[@"*"]];

    [NAV loadArticleWithTitle: pageTitle
                       domain: selectedLangInfo[@"code"]
                     animated: NO
              discoveryMethod: DISCOVERY_METHOD_SEARCH
            invalidatingCache: NO
                   popToWebVC: YES];

    [self dismissLanguagePicker];
}

-(void)dismissLanguagePicker
{
    [self.presentedViewController dismissViewControllerAnimated: YES
                                                     completion: ^{}];
}

-(void)showProtectedDialog
{
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = MWLocalizedString(@"page_protected_can_not_edit_title", nil);
    alert.message = MWLocalizedString(@"page_protected_can_not_edit", nil);
    [alert addButtonWithTitle:@"OK"];
    alert.cancelButtonIndex = 0;
    [alert show];
}

#pragma mark Refs

-(void)setReferencesHidden:(BOOL)referencesHidden
{
    if (self.referencesHidden == referencesHidden) return;

    _referencesHidden = referencesHidden;

    [self updateReferencesHeightAndBottomConstraints];

    if (referencesHidden) {
        // Cause the highlighted ref link in the webView to no longer be highlighted.
        [self.referencesVC reset];
    }

    // Fade out refs when hidden.
    CGFloat alpha = referencesHidden ? 0.0 : 1.0;
    
    self.referencesContainerView.alpha = alpha;
}

-(void)updateReferencesHeightAndBottomConstraints
{
    CGFloat refsHeight = [self getRefsPanelHeight];
    self.referencesContainerViewBottomConstraint.constant = self.referencesHidden ? refsHeight : 0.0;
    self.referencesContainerViewHeightConstraint.constant = refsHeight;
}

-(CGFloat)getRefsPanelHeight
{
    CGFloat percentOfHeight = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.4 : 0.6;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) percentOfHeight *= 0.5;
    NSNumber *refsHeight = @(self.view.frame.size.height * percentOfHeight);
    return (CGFloat)refsHeight.integerValue;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateReferencesHeightAndBottomConstraints];
}

-(void)referencesShow:(NSDictionary *)payload
{
    if (!self.referencesHidden){
        self.referencesVC.panelHeight = [self getRefsPanelHeight];
        self.referencesVC.payload = payload;
        return;
    }
    
    self.referencesVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"ReferencesVC"];
    
    self.referencesVC.webVC = self;
    [self addChildViewController:self.referencesVC];
    self.referencesVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.referencesContainerView addSubview:self.referencesVC.view];
    
    [self.referencesContainerView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[view]|"
                                             options: 0
                                             metrics: nil
                                               views: @{@"view": self.referencesVC.view}]];
    [self.referencesContainerView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[view]|"
                                             options: 0
                                             metrics: nil
                                               views: @{@"view": self.referencesVC.view}]];
    
    [self.referencesVC didMoveToParentViewController:self];

    [self.referencesContainerView layoutIfNeeded];

    self.referencesVC.panelHeight = [self getRefsPanelHeight];
    self.referencesVC.payload = payload;
    
    [UIView animateWithDuration: 0.16
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{
                         self.referencesHidden = NO;
                         [self.view layoutIfNeeded];
                     }completion:nil];
}

-(void)referencesHide
{
    if (self.referencesHidden) return;
    [UIView animateWithDuration: 0.16
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{
                         self.referencesHidden = YES;

                         [self.view layoutIfNeeded];
                     }completion:^(BOOL done){
                         [self.referencesVC willMoveToParentViewController:nil];
                         [self.referencesVC.view removeFromSuperview];
                         [self.referencesVC removeFromParentViewController];
                         self.referencesVC = nil;
                     }];
}

@end
