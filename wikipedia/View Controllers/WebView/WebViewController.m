//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewController.h"

#import "WikipediaAppUtils.h"
#import "WikipediaZeroMessageFetcher.h"
#import "ArticleDataContextSingleton.h"
#import "SectionEditorViewController.h"
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
#import "WMF_Colors.h"
#import "NSArray+Predicate.h"
#import "WikiGlyphButton.h"
#import "WikiGlyphLabel.h"
#import "WikiGlyph_Chars_iOS.h"
#import "NSString+FormattedAttributedString.h"
#import "SavedPagesFunnel.h"

#import "ArticleFetcher.h"
#import "AssetsFileFetcher.h"

//#import "UIView+Debugging.h"

#define TOC_TOGGLE_ANIMATION_DURATION @0.225f

#define SCROLL_INDICATOR_LEFT_MARGIN 2.0
#define SCROLL_INDICATOR_WIDTH 4.0
#define SCROLL_INDICATOR_HEIGHT 25.0
#define SCROLL_INDICATOR_CORNER_RADIUS 2.0f
#define SCROLL_INDICATOR_BORDER_WIDTH 1.0f
#define SCROLL_INDICATOR_BORDER_COLOR [UIColor lightGrayColor]
#define SCROLL_INDICATOR_BACKGROUND_COLOR [UIColor whiteColor]

#define BOTTOM_SCROLL_LIMIT_HEIGHT 2000

// This controls how fast the swipe has to be (side-to-side).
#define TOC_SWIPE_TRIGGER_MIN_X_VELOCITY 600.0f
// This controls what angle from the horizontal axis will trigger the swipe.
#define TOC_SWIPE_TRIGGER_MAX_ANGLE 45.0f

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

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tocViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tocViewLeadingConstraint;

@property (strong, nonatomic) UIView *scrollIndicatorView;
@property (strong, nonatomic) NSLayoutConstraint *scrollIndicatorViewTopConstraint;
@property (strong, nonatomic) NSLayoutConstraint *scrollIndicatorViewHeightConstraint;

@property (strong, nonatomic) TOCViewController *tocVC;

@property (strong, nonatomic) UIPanGestureRecognizer* panSwipeRecognizer;

@property (strong, nonatomic) IBOutlet PaddedLabel *zeroStatusLabel;

@property (nonatomic) BOOL unsafeToToggleTOC;

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

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomNavHeightConstraint;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIView *activityIndicatorBackgroundView;

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

    self.bottomNavHeightConstraint.constant = CHROME_MENUS_HEIGHT;
    
    self.scrollingToTop = NO;

    [self scrollIndicatorSetup];

    self.panSwipeRecognizer = nil;

    self.zeroStatusLabel.font = [UIFont systemFontOfSize:ALERT_FONT_SIZE];
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

    [self tocSetupSwipeGestureRecognizers];

    [self reloadCurrentArticleInvalidatingCache:NO];
    
    // Restrict the web view from scrolling horizonally.
    [self.webView.scrollView addObserver: self
                              forKeyPath: @"contentSize"
                                 options: NSKeyValueObservingOptionNew
                                 context: nil];

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

    self.webView.scrollView.scrollsToTop = YES;
    self.tocVC.scrollView.scrollsToTop = NO;

    // Uncomment these lines only if testing onboarding!
    // These lines allow the onboarding to run on every app cold start.
    //[[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"ShowOnboarding"];
    //[[NSUserDefaults standardUserDefaults] synchronize];

    //self.referencesContainerView.layer.borderWidth = 10;
    //self.referencesContainerView.layer.borderColor = [UIColor redColor].CGColor;

    // Ensure toc show/hide animation scales the web view w/o vertical motion.
    BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];
    self.webView.scrollView.layer.anchorPoint = CGPointMake((isRTL ? 1.0 : 0.0), 0.0);

    /*
    self.webView.scrollView.layer.borderWidth = 6;
    self.webView.scrollView.layer.borderColor = [UIColor redColor].CGColor;
    self.webView.layer.borderWidth = 2;
    self.webView.layer.borderColor = [UIColor greenColor].CGColor;
    */

    [self tocUpdateViewLayout];
    
    [self loadingIndicatorAdd];
}

-(void)tocUpdateViewLayout
{
    CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
    CGFloat tocWidth = [self tocGetWidthForWebViewScale:webViewScale];
    self.tocViewLeadingConstraint.constant = 0;
    self.tocViewWidthConstraint.constant = tocWidth;
}

-(void)showAlert:(id)alertText type:(AlertType)type duration:(CGFloat)duration
{
    if ([self tocDrawerIsOpen]) return;

    // Don't show alerts if onboarding onscreen.
    if ([self shouldShowOnboarding]) return;

    [super showAlert:alertText type:type duration:duration];
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

    [[QueuesSingleton sharedInstance].zeroRatedMessageFetchManager.operationQueue cancelAllOperations];
    
    [super viewWillDisappear:animated];
}

#pragma mark Scroll indicator

-(void)scrollIndicatorSetup
{
    self.scrollIndicatorView = [[UIView alloc] init];
    self.scrollIndicatorView.opaque = YES;
    self.scrollIndicatorView.backgroundColor = SCROLL_INDICATOR_BACKGROUND_COLOR;
    self.scrollIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollIndicatorView.layer.cornerRadius = SCROLL_INDICATOR_CORNER_RADIUS;
    self.scrollIndicatorView.layer.borderWidth = SCROLL_INDICATOR_BORDER_WIDTH / [UIScreen mainScreen].scale;
    self.scrollIndicatorView.layer.borderColor = SCROLL_INDICATOR_BORDER_COLOR.CGColor;

    self.webView.scrollView.showsHorizontalScrollIndicator = NO;
    self.webView.scrollView.showsVerticalScrollIndicator = NO;
    
    [self.webView addSubview:self.scrollIndicatorView];

    self.scrollIndicatorViewTopConstraint =
    [NSLayoutConstraint constraintWithItem: self.scrollIndicatorView
                                 attribute: NSLayoutAttributeTop
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: self.webView
                                 attribute: NSLayoutAttributeTop
                                multiplier: 1.0
                                  constant: 0.0];

    [self.view addConstraint:self.scrollIndicatorViewTopConstraint];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem: self.scrollIndicatorView
                                                          attribute: NSLayoutAttributeTrailing
                                                          relatedBy: NSLayoutRelationEqual
                                                             toItem: self.webView
                                                          attribute: NSLayoutAttributeTrailing
                                                         multiplier: 1.0
                                                           constant: -SCROLL_INDICATOR_LEFT_MARGIN]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem: self.scrollIndicatorView
                                                          attribute: NSLayoutAttributeWidth
                                                          relatedBy: NSLayoutRelationEqual
                                                             toItem: nil
                                                          attribute: NSLayoutAttributeNotAnAttribute
                                                         multiplier: 1.0
                                                           constant: SCROLL_INDICATOR_WIDTH]];
    
    self.scrollIndicatorViewHeightConstraint =
    [NSLayoutConstraint constraintWithItem: self.scrollIndicatorView
                                 attribute: NSLayoutAttributeHeight
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: nil
                                 attribute: NSLayoutAttributeNotAnAttribute
                                multiplier: 1.0
                                  constant: SCROLL_INDICATOR_HEIGHT];

    [self.view addConstraint:self.scrollIndicatorViewHeightConstraint];
}

-(void)scrollIndicatorMove
{
    CGFloat f = self.webView.scrollView.contentSize.height - BOTTOM_SCROLL_LIMIT_HEIGHT;
    if (f == 0) f = 0.00001f;
    //self.scrollIndicatorView.alpha = [self tocDrawerIsOpen] ? 0.0f : 1.0f;
    CGFloat percent = self.webView.scrollView.contentOffset.y / f;
    //NSLog(@"percent = %f", percent);
    self.scrollIndicatorViewTopConstraint.constant = percent * (self.bottomBarView.frame.origin.y - SCROLL_INDICATOR_HEIGHT) + 8.0;
}

#pragma mark Sync config/ios.json if necessary

-(void)downloadAssetsFilesIfNecessary
{
    // Sync config/ios.json at most once per day.
    CGFloat maxAge = 60 * 60 * 24;

    [[QueuesSingleton sharedInstance].assetsFetchManager.operationQueue cancelAllOperations];

    void (^fetch)(AssetsFileEnum) = ^void(AssetsFileEnum type) {
        (void)[[AssetsFileFetcher alloc] initAndFetchAssetsFile: type
                                                    withManager: [QueuesSingleton sharedInstance].assetsFetchManager
                                                         maxAge: maxAge];
    };
    
    fetch(ASSETS_FILE_CONFIG);
    fetch(ASSETS_FILE_CSS);
    fetch(ASSETS_FILE_CSS_ABUSE_FILTER);
    fetch(ASSETS_FILE_CSS_PREVIEW);
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
    [super updateViewConstraints];

    [self constrainBottomMenu];
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
    return !CGAffineTransformIsIdentity(self.webView.scrollView.transform);
}

-(void)tocHideWithDuration:(NSNumber *)duration
{
    if ([self tocDrawerIsOpen]){
 
        // Note: don't put this on the mainQueue. It can cause problems
        // if the toc needs to be hidden with 0 duration, such as when
        // the device is rotated. (could wrap this in a block and add
        // it to mainQueue if duration not 0, or directly call the block
        // if duration is 0, but I don't think we need to.)
        
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
                             self.scrollIndicatorView.alpha = 1.0;
                             // If the top menu isn't hidden, reveal the bottom menu.
                             self.bottomMenuHidden = ROOT.topMenuHidden;
                             
                             self.webView.scrollView.transform = CGAffineTransformIdentity;
                             
                             self.referencesContainerView.transform = CGAffineTransformIdentity;
                             
                             self.bottomBarView.transform = CGAffineTransformIdentity;

                             self.tocViewLeadingConstraint.constant = 0;
                             
                             [self.view layoutIfNeeded];
                         }completion: ^(BOOL done){
                             [self.tocVC didHide];
                             self.unsafeToToggleTOC = NO;
                             self.webView.scrollView.contentOffset = origScrollPosition;
                             
                             WikiGlyphButton *tocButton = [ROOT.topMenuViewController getNavBarItem:NAVBAR_BUTTON_TOC];
                             [tocButton.label setWikiText: IOS_WIKIGLYPH_TOC_COLLAPSED
                                                    color: tocButton.label.color
                                                     size: tocButton.label.size
                                           baselineOffset: tocButton.label.baselineOffset];
                         }];
    }
}

-(void)tocShowWithDuration:(NSNumber *)duration
{
    if ([self tocDrawerIsOpen]) return;

    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        
        self.unsafeToToggleTOC = YES;
        
        // Hide any alerts immediately.
        [self hideAlert];
        
        [self.tocVC willShow];
        
        [self tocUpdateViewLayout];
        [self.view layoutIfNeeded];

        [UIView animateWithDuration: duration.floatValue
                              delay: 0.0f
                            options: UIViewAnimationOptionBeginFromCurrentState
                         animations: ^{
                             self.scrollIndicatorView.alpha = 0.0;
                             self.bottomMenuHidden = YES;
                             self.referencesHidden = YES;

                             CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
                             CGAffineTransform xf = CGAffineTransformMakeScale(webViewScale, webViewScale);

                             self.webView.scrollView.transform = xf;
                             self.referencesContainerView.transform = xf;
                             self.bottomBarView.transform = xf;

                             CGFloat tocWidth = [self tocGetWidthForWebViewScale:webViewScale];
                             self.tocViewLeadingConstraint.constant = -tocWidth;

                             // Scroll down by one pixel during the animation. This is a hack fix to cause
                             // the web scroll view to not sometimes have a small bit of blank white space
                             // at the bottom after this toc show animation finishes.
                             self.webView.scrollView.contentOffset =
                                 CGPointMake(
                                     self.webView.scrollView.contentOffset.x,
                                     self.webView.scrollView.contentOffset.y - 1.0
                                 );

                             [self.view layoutIfNeeded];
                             
                         }completion: ^(BOOL done){
                             self.unsafeToToggleTOC = NO;
                             
                             WikiGlyphButton *tocButton = [ROOT.topMenuViewController getNavBarItem:NAVBAR_BUTTON_TOC];
                             [tocButton.label setWikiText: IOS_WIKIGLYPH_TOC_EXPANDED
                                                    color: tocButton.label.color
                                                     size: tocButton.label.size
                                           baselineOffset: tocButton.label.baselineOffset];
                         }];
    }];
}

- (void)viewDidLayoutSubviews
{
    [self increaseWebViewScrollViewHeight];
    
    // See: http://stackoverflow.com/a/17419858
    [self.view layoutSubviews];
}

-(void)increaseWebViewScrollViewHeight
{
    // Reminder: can't do this when isDragging or isDecelerating
    // because pull to refresh won't work.
    if (!self.webView.scrollView.isDragging && !self.webView.scrollView.isDecelerating) {
        // When the TOC is shown, the self.webView.scrollView.transform is changed, but this
        // causes the height of the scrollView to be reduced, which doesn't mess anything up
        // visually, but does cause the area beneath the scrollView to no longer respond to
        // drag events. Turn on border for scrollView to see this (and comment out call to
        // this method). So here *only* the scrollView's height is updated.
        self.webView.scrollView.frame =
        CGRectMake(
                   self.webView.scrollView.frame.origin.x,
                   self.webView.scrollView.frame.origin.y,
                   self.webView.scrollView.frame.size.width,
                   self.webView.frame.size.height
                   );
    }
}

-(void)tocHide
{
    if(self.unsafeToToggleTOC) return;

    [self tocHideWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

-(void)tocShow
{
    // Prevent toc reveal if pull to refresh in effect.
    if (self.webView.scrollView.contentOffset.y < 0) return;

    // Prevent toc reveal if loading article.
    if (self.activityIndicator.isAnimating) return;

    NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;
    if (!currentArticleTitle || (currentArticleTitle.length == 0)) return;
    if (!self.referencesHidden) return;

    if([[SessionSingleton sharedInstance] isCurrentArticleMain]) return;

    if(self.unsafeToToggleTOC) return;

    [self tocShowWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

-(void)tocToggle
{
    // Clear alerts
    [self fadeAlert];

    [self referencesHide];

    if ([self tocDrawerIsOpen]) {
        [self tocHide];
    }else{
        [self tocShow];
    }
}

-(BOOL)shouldPanVelocityTriggerTOC:(CGPoint)panVelocity
{
    CGFloat angleFromHorizontalAxis = [self getAbsoluteHorizontalDegreesFromVelocity:panVelocity];
    if (
        (angleFromHorizontalAxis < TOC_SWIPE_TRIGGER_MAX_ANGLE)
        &&
        (fabsf(panVelocity.x) > TOC_SWIPE_TRIGGER_MIN_X_VELOCITY)
    ) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Don't allow the web view's scroll view or the TOC's scroll view to start vertical scrolling if the
    // angle and direction of the swipe are within tolerances to trigger TOC toggle. Needed because you
    // don't want either of these to be scrolling vertically when the TOC is being revealed or hidden.
    //WHOA! see this: http://stackoverflow.com/a/18834934
    if (gestureRecognizer == self.panSwipeRecognizer) {
        if (
            (otherGestureRecognizer == self.webView.scrollView.panGestureRecognizer)
            ||
            (otherGestureRecognizer == self.tocVC.scrollView.panGestureRecognizer)
        ){
            UIPanGestureRecognizer *otherPanRecognizer = (UIPanGestureRecognizer *)otherGestureRecognizer;
            CGPoint velocity = [otherPanRecognizer velocityInView:otherGestureRecognizer.view];
            if ([self shouldPanVelocityTriggerTOC:velocity]) {
                // Kill vertical scroll before it starts if we're going to show TOC.
                self.webView.scrollView.panGestureRecognizer.enabled = NO;
                self.webView.scrollView.panGestureRecognizer.enabled = YES;
                self.tocVC.scrollView.panGestureRecognizer.enabled = NO;
                self.tocVC.scrollView.panGestureRecognizer.enabled = YES;
            }
        }
    }
    return YES;
}

-(void)tocSetupSwipeGestureRecognizers
{
    // Use pan instead for swipe so we can control speed at which swipe triggers. Idea from:
    // http://www.mindtreatstudios.com/how-its-made/ios-gesture-recognizer-tips-tricks/

    self.panSwipeRecognizer =
        [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanSwipe:)];
    self.panSwipeRecognizer.delegate = self;
    self.panSwipeRecognizer.minimumNumberOfTouches = 1;
    [self.view addGestureRecognizer:self.panSwipeRecognizer];
}

- (void)handlePanSwipe:(UIPanGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded){
        
        CGPoint velocity = [recognizer velocityInView:recognizer.view];

        if (![self shouldPanVelocityTriggerTOC:velocity] || self.webView.scrollView.isDragging) return;
        
        // Device rtl value is checked since this is what would cause the other constraints to flip.
        BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];

        if (velocity.x < 0){
            //NSLog(@"swipe left");
            if (isRTL) {
                [self tocHide];
            }else{
                [self tocShow];
            }
        }else if (velocity.x > 0){
            //NSLog(@"swipe right");
            if (isRTL) {
                [self tocShow];
            }else{
                [self tocHide];
            }
        }
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


-(CGFloat)tocGetPercentOnscreen
{
    CGFloat defaultWebViewScaleWhenTOCVisible = [self tocGetWebViewScaleWhenTOCVisible];
    CGFloat defaultTOCWidth = [self tocGetWidthForWebViewScale:defaultWebViewScaleWhenTOCVisible];
    return 1.0f - (fabsf(self.tocVC.view.frame.origin.x) / defaultTOCWidth);
}

-(BOOL)rectIntersectsWebViewTop:(CGRect)rect
{
    CGFloat elementScreenYOffset =
        rect.origin.y - self.webView.scrollView.contentOffset.y + rect.size.height;
    return (elementScreenYOffset > 0) && (elementScreenYOffset < rect.size.height);
}

-(void)tocScrollWebViewToSectionWithElementId: (NSString *)elementId
                                     duration: (CGFloat)duration
                                  thenHideTOC: (BOOL)hideTOC
{
    CGRect r = [self.webView getWebViewRectForHtmlElementWithId:elementId];
    if (CGRectIsNull(r)) return;

    // Determine if the element is already intersecting the top of the screen.
    // The method below is more efficient than calling
    // getScreenRectForHtmlElementWithId again (as it was already called by
    // getWebViewRectForHtmlElementWithId).
    // if ([self rectIntersectsWebViewTop:r]) return;
    
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
    }
}

#pragma mark Dealloc

-(void)dealloc
{
    [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize"];

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
                   invalidatingCache: NO
                showLoadingIndicator: YES];
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

        // Tiny delay prevents menus from occasionally appearing when user swipes to reveal toc.
        [weakSelf performSelector:@selector(animateTopAndBottomMenuReveal) withObject:nil afterDelay:0.05];

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
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                                                      domain: [SessionSingleton sharedInstance].currentArticleDomain];
        if (!articleID) return;
        Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
        if (!article || !article.title || !article.domain) return;

        SavedPagesFunnel *funnel = [[SavedPagesFunnel alloc] init];
        if (article.saved.count == 0) {
            // Show alert.
            [self showPageSavedAlertMessageForTitle:article.title];

            // Actually perform the save.
            Saved *saved = [NSEntityDescription insertNewObjectForEntityForName:@"Saved" inManagedObjectContext:articleDataContext_.mainContext];
            saved.dateSaved = [NSDate date];
            [article addSavedObject:saved];
            [funnel logSaveNew];
        }else{
            // Unsave!
            //[articleDataContext_.mainContext deleteObject:article.saved.anyObject];
            for (id obj in article.saved.copy) {
                [articleDataContext_.mainContext deleteObject:obj];
            }
            [self fadeAlert];
            [funnel logDelete];
        }
        NSError *error = nil;
        [articleDataContext_.mainContext save:&error];
        NSLog(@"SAVE PAGE ERROR = %@", error);
    }];
}

-(void)showPageSavedAlertMessageForTitle:(NSString *)title
{
    // First show saved message.
    NSString *savedMessage = MWLocalizedString(@"share-menu-page-saved", nil);
    
    NSMutableAttributedString *attributedSavedMessage =
    [savedMessage attributedStringWithAttributes: @{}
                             substitutionStrings: @[title]
                          substitutionAttributes: @[@{NSFontAttributeName: [UIFont italicSystemFontOfSize:ALERT_FONT_SIZE]}]].mutableCopy;
    
    CGFloat duration = 2.0;
    BOOL AccessSavedPagesMessageShown = [[NSUserDefaults standardUserDefaults] boolForKey:@"AccessSavedPagesMessageShown"];
    
    //AccessSavedPagesMessageShown = NO;
    
    if (!AccessSavedPagesMessageShown) {
        duration = -1;
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"AccessSavedPagesMessageShown"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSString *accessMessage = [NSString stringWithFormat:@"\n%@", MWLocalizedString(@"share-menu-page-saved-access", nil)];
        
        NSDictionary *d = @{
                            NSFontAttributeName: [UIFont fontWithName:@"WikiFontGlyphs-iOS" size:ALERT_FONT_SIZE],
                            NSBaselineOffsetAttributeName : @2
                            };
        
        NSAttributedString *attributedAccessMessage =
        [accessMessage attributedStringWithAttributes: @{}
                                  substitutionStrings: @[IOS_WIKIGLYPH_W, IOS_WIKIGLYPH_HEART]
                               substitutionAttributes: @[d, d]];
        
        
        [attributedSavedMessage appendAttributedString:attributedAccessMessage];
    }
    
    [self showAlert:attributedSavedMessage type:ALERT_TYPE_BOTTOM duration:duration];
}

#pragma mark Web view scroll offset recording

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(!decelerate) [self scrollViewScrollingEnded:scrollView];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self scrollViewScrollingEnded:scrollView];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    // If user quickly scrolls web view make toc update when user lifts finger.
    // (in addition to when scroll ends)
    if (scrollView == self.webView.scrollView) {
        [self.tocVC centerCellForWebViewTopMostSectionAnimated:YES];
    }
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
        
        [self.tocVC centerCellForWebViewTopMostSectionAnimated:YES];

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

#pragma mark Web view limit scroll up

- (void)limitScrollUp:(UIScrollView *)webScrollView
{
    // When trying to scroll the bottom of the web view article all the way to
    // the top, this is the minimum amount that will be allowed to be onscreen
    // before we limit scrolling.
    CGFloat onscreenMinHeight = 210;
    
    CGFloat offsetMaxY = BOTTOM_SCROLL_LIMIT_HEIGHT + onscreenMinHeight;
    
    if ((webScrollView.contentSize.height - webScrollView.contentOffset.y) < offsetMaxY){
        CGPoint p = CGPointMake(webScrollView.contentOffset.x,
                                webScrollView.contentSize.height - offsetMaxY);

        // This limits scrolling!
        [webScrollView setContentOffset:p animated: NO];
    }
}

#pragma mark Scroll hiding keyboard threshold

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.webView.scrollView) {
        [self limitScrollUp:scrollView];
    }

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

    [self scrollIndicatorMove];

    if (![self tocDrawerIsOpen]){
        [self adjustTopAndBottomMenuVisibilityOnScroll];
        // No need to report scroll event to pull to refresh super vc if toc open.
        [super scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    scrollViewDragBeganVerticalOffset_ = scrollView.contentOffset.y;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [self.tocVC centerCellForWebViewTopMostSectionAnimated:NO];
    [self saveWebViewScrollOffset];
    self.scrollingToTop = NO;
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
    if (![self tocDrawerIsOpen]) {
        if (ROOT.topMenuViewController.navBarMode != NAVBAR_MODE_SEARCH) {
            [ROOT animateTopAndBottomMenuHidden:NO];
        }
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    self.scrollingToTop = YES;
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

    //[self downloadAssetsFilesIfNecessary];

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

    //NSLog(@"articleFetchManager.operationCount = %lu", (unsigned long)[QueuesSingleton sharedInstance].articleFetchManager.operationQueue.operationCount);
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

-(void)navigateToPage: (MWPageTitle *)title
               domain: (NSString *)domain
      discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod
    invalidatingCache: (BOOL)invalidateCache
 showLoadingIndicator: (BOOL)showLoadingIndicator
{
    NSString *cleanTitle = title.text;
    
    // Don't try to load nothing. Core data takes exception with such nonsense.
    if (cleanTitle == nil) return;
    if (cleanTitle.length == 0) return;
    
    [self hideKeyboard];
    
    if(showLoadingIndicator) [self loadingIndicatorShow];
    
    // Show loading message
    //[self showAlert:MWLocalizedString(@"search-loading-section-zero", nil) type:ALERT_TYPE_TOP duration:-1];

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
    NSManagedObjectID *articleID =
    [articleDataContext_.mainContext getArticleIDForTitle: pageTitle.prefixedText
                                                   domain: domain];
    if (articleID) {
        [articleDataContext_.mainContext performBlockAndWait:^(){
            Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
            if (article) {
                article.needsRefresh = @YES;
                NSError *error = nil;
                [articleDataContext_.mainContext save:&error];
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
       invalidatingCache: invalidateCache
    showLoadingIndicator: YES];
}

- (void)fetchFinished: (id)sender
             userData: (id)userData
               status: (FetchFinalStatus)status
                error: (NSError *)error
{
    if ([sender isKindOfClass:[ArticleFetcher class]]) {
        
        ArticleFetcher *articleFetcher = (ArticleFetcher *)sender;
        Article *article = articleFetcher.article;
        
        NSNumber *articleSectionType = (NSNumber *)userData;
        
        switch (articleSectionType.integerValue) {
            case ARTICLE_SECTION_TYPE_LEAD:
                
                switch (status) {
                    case FETCH_FINAL_STATUS_SUCCEEDED:
                    {
                        // Redirect if necessary.
                        NSString *redirectedTitle = article.redirected;
                        if (redirectedTitle.length > 0) {
                            // Get discovery method for call to "retrieveArticleForPageTitle:".
                            // There should only be a single history item (at most).
                            History *history = [article.history anyObject];
                            // Get the article's discovery method string.
                            NSString *discoveryMethod =
                            (history) ? history.discoveryMethod : [NAV getStringForDiscoveryMethod:DISCOVERY_METHOD_SEARCH];
                            
                            // Remove the article so it doesn't get saved.
                            [article.managedObjectContext deleteObject:article];
                            
                            // Redirect!
                            [self retrieveArticleForPageTitle: [MWPageTitle titleWithString:redirectedTitle]
                                                       domain: article.domain
                                              discoveryMethod: discoveryMethod];
                            return;
                        }
                        
                        // Associate thumbnail with article.
                        // If search result for this pageTitle had a thumbnail url associated with it, see if
                        // a core data image object exists with a matching sourceURL. If so make the article
                        // thumbnailImage property point to that core data image object. This associates the
                        // search result thumbnail with the article.
                        NSPredicate *articlePredicate =
                        [NSPredicate predicateWithFormat:@"(title == %@) AND (thumbnail.source.length > 0)", article.titleObj.text];
                        NSDictionary *articleDictFromSearchResults =
                        [ROOT.topMenuViewController.currentSearchResultsOrdered firstMatchForPredicate:articlePredicate];
                        if (articleDictFromSearchResults) {
                            NSString *thumbURL = articleDictFromSearchResults[@"thumbnail"][@"source"];
                            thumbURL = [thumbURL getUrlWithoutScheme];
                            Image *thumb = (Image *)[article.managedObjectContext getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", thumbURL];
                            if (thumb) article.thumbnailImage = thumb;
                        }
                        
                        // Actually save the article record.
                        NSError *err = nil;
                        [article.managedObjectContext save:&err];
                        if (err) NSLog(@"Lead section save error = %@", err);
                        
                        // Update the toc and web view.
                        [self.tocVC setTocSectionDataForSections:article.section];
                        [self displayArticle:article.objectID mode:DISPLAY_LEAD_SECTION];
                        
                    }
                        break;
                    case FETCH_FINAL_STATUS_FAILED:
                    {
                        NSString *errorMsg = error.localizedDescription;
                        [self showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];
                        
                        // Remove the article so it doesn't get saved.
                        [article.managedObjectContext deleteObject:article];
                    }
                        break;
                    case FETCH_FINAL_STATUS_CANCELLED:
                    {
                        // Remove the article so it doesn't get saved.
                        [article.managedObjectContext deleteObject:article];
                    }
                        break;
                        
                    default:
                        break;
                }
                
                break;
                
            case ARTICLE_SECTION_TYPE_NON_LEAD:
                
                switch (status) {
                    case FETCH_FINAL_STATUS_SUCCEEDED:
                    {
                        // Save the article record.
                        NSError *err = nil;
                        [article.managedObjectContext save:&err];
                        if (err) NSLog(@"Non-lead section save error = %@", err);
                        
                        // Update the toc and web view.
                        [self.tocVC setTocSectionDataForSections:article.section];
                        [self displayArticle:article.objectID mode:DISPLAY_APPEND_NON_LEAD_SECTIONS];
                        
                    }
                        break;
                    case FETCH_FINAL_STATUS_FAILED:
                    {
                        NSString *errorMsg = error.localizedDescription;
                        [self showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];
                    }
                        break;
                    case FETCH_FINAL_STATUS_CANCELLED:
                        [self fadeAlert];
                        break;
                        
                    default:
                        break;
                }
                
                break;
            default:
                break;
        }

    } else if ([sender isKindOfClass:[WikipediaZeroMessageFetcher class]]) {

        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
            {
                NSDictionary *banner = (NSDictionary*)userData;
                if (banner) {
                    TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
                    textFieldContainer.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text-zero", nil);
                    
                    //[self showAlert:title type:ALERT_TYPE_TOP duration:2];
                    NSString *title = banner[@"message"];
                    self.zeroStatusLabel.text = title;
                    self.zeroStatusLabel.padding = UIEdgeInsetsMake(3, 10, 3, 10);
                    self.zeroStatusLabel.textColor = banner[@"foreground"];
                    self.zeroStatusLabel.backgroundColor = banner[@"background"];
                    
                    [NAV promptFirstTimeZeroOnWithTitleIfAppropriate:title];
                }
            }
                break;
            case FETCH_FINAL_STATUS_FAILED:
            {
                
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
            {
                
            }
                break;
        }
    }

}

- (void)retrieveArticleForPageTitle: (MWPageTitle *)pageTitle
                             domain: (NSString *)domain
                    discoveryMethod: (NSString *)discoveryMethod
{
    // Cancel certain in-progress fetches.
    [[QueuesSingleton sharedInstance].articleFetchManager.operationQueue cancelAllOperations];
    [[QueuesSingleton sharedInstance].searchResultsFetchManager.operationQueue cancelAllOperations];

    [articleDataContext_.mainContext performBlockAndWait:^(){
        
        __block NSManagedObjectID *articleID =
        [articleDataContext_.mainContext getArticleIDForTitle: pageTitle.prefixedText
                                                       domain: domain];
        BOOL needsRefresh = NO;
        
        Article *article = nil;
        if (articleID) {
            article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
            
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
                [self.tocVC setTocSectionDataForSections:article.section];
                [self displayArticle:articleID mode:DISPLAY_ALL_SECTIONS];
                //[self showAlert:MWLocalizedString(@"search-loading-article-loaded", nil) type:ALERT_TYPE_TOP duration:-1];
                [self fadeAlert];
                return;
            }
            needsRefresh = article.needsRefresh.boolValue;
            
        }else{
            
            article = [NSEntityDescription
                       insertNewObjectForEntityForName:@"Article"
                       inManagedObjectContext:articleDataContext_.mainContext
                       ];
            article.lastmodifiedby = @"";
            article.redirected = @"";
            article.title = pageTitle.prefixedText;
            article.dateCreated = [NSDate date];
            article.site = [SessionSingleton sharedInstance].site;
            article.domain = [SessionSingleton sharedInstance].currentArticleDomain;
            article.domainName = [SessionSingleton sharedInstance].currentArticleDomainName;
            articleID = article.objectID;
            
            // Add history record.
            // Note: don't add multiple history items for the same article or back-forward
            // button behavior becomes a confusing mess.
            History *newHistory =
            [NSEntityDescription insertNewObjectForEntityForName: @"History"
                                          inManagedObjectContext: article.managedObjectContext];
            newHistory.dateVisited = [NSDate date];
            //newHistory.dateVisited = [NSDate dateWithDaysBeforeNow:31];
            newHistory.discoveryMethod = discoveryMethod;
            [article addHistoryObject:newHistory];
        }
        
        if (needsRefresh) {
            // If and article needs refreshing remove its sections so they get reloaded too.
            for (Section *thisSection in [article.section copy]) {
                [articleDataContext_.mainContext deleteObject:thisSection];
            }
        }
        
        // "fetchFinished:" above will be notified when articleFetcher has actually retrieved some data.
        // Note: cast to void to avoid compiler warning: http://stackoverflow.com/a/7915839
        (void)[[ArticleFetcher alloc] initAndFetchSectionsForArticle: article
                                                         withManager: [QueuesSingleton sharedInstance].articleFetchManager
                                                  thenNotifyDelegate: self];

    }];
}

#pragma mark Display article from core data

- (void)displayArticle:(NSManagedObjectID *)articleID mode:(DisplayMode)mode
{
    // Get sorted sections for this article (sorts the article.section NSSet into sortedSections)
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sectionId" ascending:YES];

    Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];

    if (!article || !article.title || !article.domain) return;
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

        if (mode != DISPLAY_APPEND_NON_LEAD_SECTIONS) {
            if (![[SessionSingleton sharedInstance] isCurrentArticleMain]) {
                if (mode == DISPLAY_LEAD_SECTION) {
                    [sectionTextArray addObject: [NSString stringWithFormat:@"<div id='nonLeadSectionsInjectionPoint' style='margin-top:2em;margin-bottom:2em;'>%@</div>", MWLocalizedString(@"search-loading-section-remaining", nil)]];
                }

                [sectionTextArray addObject: [self renderFooterDivider]];
                [sectionTextArray addObject: [self renderLastModified:lastModified by:lastModifiedBy]];
                [sectionTextArray addObject: [self renderLanguageButtonForCount: langCount.integerValue]];
                [sectionTextArray addObject: [self renderLicenseFooter]];
            }

            // This is important! Ensures bottom of web view article can be scrolled closer to the top of
            // the screen. Works in conjunction with "limitScrollUp:" method.
            // Note: had to add "px" to the height because we added "<!DOCTYPE html>" to the top
            // of the index.html - it won't actually give the div height w/o this now (no longer
            // using quirks mode now that doctype specified).
            [sectionTextArray addObject: [NSString stringWithFormat:@"<div style='height:%dpx;background-color:white;'></div>", BOTTOM_SCROLL_LIMIT_HEIGHT]];
        }

        
        // Join article sections text
        NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
        NSString *htmlStr = [sectionTextArray componentsJoinedByString:joint];

        // If any of these are nil, the bridge "sendMessage:" calls will crash! So catch 'em here.
        BOOL safeToCrossBridge = (languageInfo.code && languageInfo.dir && uidir && htmlStr);
        if (!safeToCrossBridge) {
            NSLog(@"\n\nUnsafe to cross JS bridge!");
            NSLog(@"\tlanguageInfo.code = %@", languageInfo.code);
            NSLog(@"\tlanguageInfo.dir = %@", languageInfo.dir);
            NSLog(@"\tuidir = %@", uidir);
            NSLog(@"\thtmlStr is nil = %d\n\n", (htmlStr == nil));
            //TODO: output "could not load page" alert and/or show last page?
            return;
        }
        
        // NSLog(@"languageInfo = %@", languageInfo.code);
        // Display all sections
        [self.bridge sendMessage: @"setLanguage"
                     withPayload: @{
                                   @"lang": languageInfo.code,
                                   @"dir": languageInfo.dir,
                                   @"uidir": uidir
                                   }];
        if (mode != DISPLAY_APPEND_NON_LEAD_SECTIONS) {
        
            [self.bridge sendMessage:@"append" withPayload:@{@"html": htmlStr}];

            [self loadingIndicatorHide];

        }else{
            [self.bridge sendMessage:@"injectNonLeadSections" withPayload:@{@"html": htmlStr}];
        }
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
        
        return [NSString stringWithFormat:@"<button id=\"mw-language-button\" dir=\"%@\" class=\"mw-language-button mw-footer-button\">"
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

    return [NSString stringWithFormat:@"<button id=\"mw-last-modified\" dir=\"%@\" class=\"mw-last-modified mw-footer-button %@\">"
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

    [self tocUpdateViewLayout];

    [self scrollToElementOnScreenBeforeRotate];
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
    [[QueuesSingleton sharedInstance].zeroRatedMessageFetchManager.operationQueue cancelAllOperations];

    if ([[[notification userInfo] objectForKey:@"state"] boolValue]) {
        (void)[[WikipediaZeroMessageFetcher alloc] initAndFetchMessageForDomain: [SessionSingleton sharedInstance].currentArticleDomain
                                                                    withManager: [QueuesSingleton sharedInstance].zeroRatedMessageFetchManager
                                                             thenNotifyDelegate: self];
    } else {
        TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
        textFieldContainer.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text", nil);
        NSString *warnVerbiage = MWLocalizedString(@"zero-charged-verbiage", nil);

        CGFloat duration = 5.0f;

        //[self showAlert:warnVerbiage type:ALERT_TYPE_TOP duration:duration];
        self.zeroStatusLabel.text = warnVerbiage;
        self.zeroStatusLabel.backgroundColor = [UIColor redColor];
        self.zeroStatusLabel.textColor = [UIColor whiteColor];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.zeroStatusLabel.text = @"";
            self.zeroStatusLabel.padding = UIEdgeInsetsZero;
        });

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
    
    return (![self tocDrawerIsOpen])
        &&
        (title && (title.length > 0))
        &&
        (!ROOT.isAnimatingTopAndBottomMenuHidden);
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

    if ([segue.identifier isEqualToString: @"TOCViewController_embed"]) {
		self.tocVC = (TOCViewController*) [segue destinationViewController];
        self.tocVC.webVC = self;
	}
}

-(void)setBottomMenuHidden:(BOOL)bottomMenuHidden
{
    if (self.bottomMenuHidden == bottomMenuHidden) return;

    _bottomMenuHidden = bottomMenuHidden;

    // Fade out the top menu when it is hidden.
    CGFloat alpha = bottomMenuHidden ? 0.0 : 1.0;
    
    self.bottomBarView.alpha = alpha;
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
    NSNumber *refsHeight = @((self.view.frame.size.height * MENUS_SCALE_MULTIPLIER) * percentOfHeight);
    return (CGFloat)refsHeight.integerValue;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Reminder: do tocHideWithDuration in willRotateToInterfaceOrientation, not here
    // (even though it makes the toc animate offscreen nicely if it was onscreen) as
    // it messes up in rtl langs for some reason, blanking out the screen.
    //[self tocHideWithDuration:@0.0f];

    [self updateReferencesHeightAndBottomConstraints];
}

-(BOOL)didFindReferencesInPayload:(NSDictionary *)payload
{
    NSArray *refs = payload[@"refs"];
    if (!refs || (refs.count == 0)) return NO;
    if (refs.count == 1) {
        NSString *firstRef = refs[0];
        if ([firstRef isEqualToString:@""]) return NO;
    }
    return YES;
}

-(void)referencesShow:(NSDictionary *)payload
{
    if (!self.referencesHidden){
        self.referencesVC.panelHeight = [self getRefsPanelHeight];
        self.referencesVC.payload = payload;
        return;
    }
    
    // Don't show refs panel if reference data has yet to be retrieved. The
    // reference parsing javascript can't parse until the reference section html has
    // been retrieved. If user taps a reference link while the non-lead sections are
    // still being retrieved we need to just not show the panel rather than showing a
    // useless blank panel.
    if (![self didFindReferencesInPayload:payload]) {
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

#pragma mark Loading Indicator

-(void)loadingIndicatorAdd
{
    self.activityIndicatorBackgroundView = [[UIView alloc] init];
    self.activityIndicatorBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    self.activityIndicatorBackgroundView.userInteractionEnabled = YES;
    self.activityIndicatorBackgroundView.backgroundColor = [UIColor whiteColor];
    self.activityIndicatorBackgroundView.alpha = 0.0;
    [self.view insertSubview:self.activityIndicatorBackgroundView belowSubview:self.bottomBarView];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.color = [UIColor whiteColor];
    self.activityIndicator.alpha = 0.0;
    [self.view addSubview:self.activityIndicator];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat activityIndicatorWidth = 100.0;
    CGFloat activityIndicatorCornerRadius = 10.0; //activityIndicatorWidth / 2.0f

    NSDictionary *views = @{
        @"activityIndicator": self.activityIndicator,
        @"activityIndicatorBackgroundView": self.activityIndicatorBackgroundView
    };
    
    NSDictionary *metrics = @{@"width": @(activityIndicatorWidth)};

    self.activityIndicator.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.85];
    self.activityIndicator.layer.cornerRadius = activityIndicatorCornerRadius;
    
    [self.view addConstraint: [NSLayoutConstraint constraintWithItem: self.activityIndicator
                                                           attribute: NSLayoutAttributeCenterX
                                                           relatedBy: NSLayoutRelationEqual
                                                              toItem: self.view
                                                           attribute: NSLayoutAttributeCenterX
                                                          multiplier: 1
                                                            constant: 0]];
    
    [self.view addConstraint: [NSLayoutConstraint constraintWithItem: self.activityIndicator
                                                           attribute: NSLayoutAttributeCenterY
                                                           relatedBy: NSLayoutRelationEqual
                                                              toItem: self.view
                                                           attribute: NSLayoutAttributeCenterY
                                                          multiplier: 1
                                                            constant: 0]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"H:[activityIndicator(width)]"
                                                                 options: 0
                                                                 metrics: metrics
                                                                   views: views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"V:[activityIndicator(width)]"
                                                                 options: 0
                                                                 metrics: metrics
                                                                   views: views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"H:|[activityIndicatorBackgroundView]|"
                                                                 options: 0
                                                                 metrics: metrics
                                                                   views: views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"V:|[activityIndicatorBackgroundView]|"
                                                                 options: 0
                                                                 metrics: metrics
                                                                   views: views]];
}

-(void)loadingIndicatorShow
{
    [self.activityIndicator startAnimating];

    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {

                        self.activityIndicatorBackgroundView.alpha = 0.7;
                        self.activityIndicator.alpha = 1.0;

                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)loadingIndicatorHide
{
    [self.activityIndicator stopAnimating];

    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {

                        self.activityIndicatorBackgroundView.alpha = 0.0;
                        self.activityIndicator.alpha = 0.0;

                     }
                     completion:^(BOOL finished) {
                     }];
}

@end
