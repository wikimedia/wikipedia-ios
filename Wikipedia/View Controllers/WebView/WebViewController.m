//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewController_Private.h"
#import <Masonry/Masonry.h>
#import "NSString+WMFHTMLParsing.h"

#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "RandomArticleFetcher.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFArticleFetcher.h"
#import "MWKSiteInfo.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "MWKLanguageLink.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

#import <BlocksKit/BlocksKit+UIKit.h>

#import "WMFShareCardViewController.h"
#import "WMFShareFunnel.h"
#import "WMFShareOptionsViewController.h"
#import "UIWebView+WMFSuppressSelection.h"
#import "WMFArticlePresenter.h"
#import "UIView+WMFRTLMirroring.h"
#import "WMFArticleViewController.h"
#import "PageHistoryViewController.h"

#import "WMFTitleOverlayLabel.h"
#import "WMFSectionTitlesViewController.h"

typedef NS_ENUM (NSInteger, WMFWebViewAlertType) {
    WMFWebViewAlertZeroWebPage,
    WMFWebViewAlertZeroCharged,
    WMFWebViewAlertZeroInterstitial
};

@interface WebViewController () <LanguageSelectionDelegate, FetchFinishedDelegate>

@property (nonatomic, strong) UIBarButtonItem* buttonTOC;
@property (nonatomic, strong) UIBarButtonItem* buttonLanguages;
@property (nonatomic, strong) UIBarButtonItem* buttonSave;
@property (nonatomic, strong) UIBarButtonItem* buttonShare;
@property (nonatomic, strong) UIBarButtonItem* buttonEditHistory;

@property (nonatomic) BOOL isAnimatingTopAndBottomMenuHidden;
@property (readonly, strong, nonatomic) MWKSiteInfoFetcher* siteInfoFetcher;
@property (strong, nonatomic) WMFArticleFetcher* articleFetcher;
@property (strong, nonatomic) UIPopoverController* popover;
@property (strong, nonatomic) WMFShareFunnel* shareFunnel;
@property (strong, nonatomic) WMFShareOptionsViewController* shareOptionsViewController;
@property (strong, nonatomic) NSString* wikipediaZeroLearnMoreExternalUrl;

@property (nonatomic, strong) WMFSectionTitlesViewController* sectionTitlesViewController;

@end

@implementation WebViewController

@synthesize siteInfoFetcher = _siteInfoFetcher;

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.session = [SessionSingleton sharedInstance];
    }
    return self;
}

- (instancetype)init {
    return [self initWithSession:[SessionSingleton sharedInstance]];
}

- (instancetype)initWithSession:(SessionSingleton*)aSession {
    NSParameterAssert(aSession);
    self = [super init];
    if (self) {
        self.session = aSession;
    }
    return self;
}

- (void)dealloc {
    [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)prefersTopNavigationHidden {
    return [self shouldShowOnboarding];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

#pragma mark View lifecycle methods

- (void)setupTopMenuButtons {
    @weakify(self)

    UIBarButtonItem * done = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemDone handler:^(id sender) {
        [self.navigationController popViewControllerAnimated:YES];
    }];

    self.navigationItem.leftBarButtonItem = done;

    self.buttonTOC = [UIBarButtonItem wmf_buttonType:WMFButtonTypeTableOfContents
                                             handler:^(id sender){
        @strongify(self)
        [self tocToggle];
    }];

    self.navigationItem.rightBarButtonItem = self.buttonTOC;
}

- (void)setupBottomMenuButtons {
    @weakify(self)
    self.buttonLanguages = [UIBarButtonItem wmf_buttonType:WMFButtonTypeTranslate handler:^(id sender){
        @strongify(self)
        [self showLanguages];
    }];

    self.buttonSave = [UIBarButtonItem wmf_buttonType:WMFButtonTypeHeart handler:^(id sender){
        @strongify(self)
        [self toggleSavedPage];
        [self updateBottomBarButtonsEnabledState];
    }];

    self.buttonShare = [UIBarButtonItem wmf_buttonType:WMFButtonTypeShare handler:^(id sender){
        @strongify(self)
        [self shareUpArrowButtonPushed];
    }];

    self.buttonEditHistory = [UIBarButtonItem wmf_buttonType:WMFButtonTypePencil handler:^(id sender){
        @strongify(self)
        [self editHistoryButtonPushed];
    }];

    self.navigationController.toolbarHidden = NO;
    self.toolbarItems                       = @[
        self.buttonEditHistory,
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        self.buttonSave,
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        self.buttonLanguages,
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        self.buttonShare
    ];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.sectionTitlesViewController = [[WMFSectionTitlesViewController alloc] initWithView:self.view webView:self.webView topLayoutGuide:self.mas_topLayoutGuide];

    [self.navigationController.navigationBar wmf_mirrorIfDeviceRTL];
    [self.navigationController.toolbar wmf_mirrorIfDeviceRTL];

    [self setupTopMenuButtons];
    [self setupBottomMenuButtons];

    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;

    self.scrollingToTop = NO;

    self.panSwipeRecognizer = nil;

    self.zeroStatusLabel.font = [UIFont systemFontOfSize:ALERT_FONT_SIZE];
    self.zeroStatusLabel.text = @"";

    self.referencesVC = nil;

    __weak WebViewController* weakSelf = self;
    [self.bridge addListener:@"DOMContentLoaded" withBlock:^(NSString* type, NSDictionary* payload) {
        [weakSelf jumpToFragmentIfNecessary];
        [weakSelf autoScrollToLastScrollOffsetIfNecessary];

        [weakSelf updateProgress:1.0 animated:YES completion:^{
            [weakSelf hideProgressViewAnimated:YES];
        }];

        //dispatching because the toc is expensive to create so we are waiting to update it after the web view renders.
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tocVC updateTocForArticle:[SessionSingleton sharedInstance].currentArticle];
            [weakSelf updateTOCScrollPositionWithoutAnimationIfHidden];
            [weakSelf.sectionTitlesViewController resetOverlays];
        });
    }];

    self.unsafeToScroll    = NO;
    self.unsafeToToggleTOC = NO;
    self.lastScrollOffset  = CGPointZero;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toggleSavedPage)
                                                 name:@"SavePage"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(searchFieldBecameFirstResponder)
                                                 name:@"SearchFieldBecameFirstResponder"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(zeroStateChanged:)
                                                 name:WMFURLCacheZeroStateChanged
                                               object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    [self fadeAlert];

    self.scrollViewDragBeganVerticalOffset = 0.0f;

    // Ensure web view can appear beneath translucent nav bar when scrolled up
    for (UIView* subview in self.webView.subviews) {
        subview.clipsToBounds = NO;
    }

    // Ensure the keyboard hides if the web view is scrolled
    // We already are delegate from PullToRefreshViewController
    //self.webView.scrollView.delegate = self;

    self.webView.backgroundColor = [UIColor whiteColor];

    [self.webView hideScrollGradient];

    [self tocSetupSwipeGestureRecognizers];

    // UIWebView has a bug which causes a black bar to appear at
    // bottom of the web view if toc quickly dragged on and offscreen.
    self.webView.opaque = NO;

    self.view.backgroundColor = CHROME_COLOR;

    // Uncomment these lines only if testing onboarding!
    // These lines allow the onboarding to run on every app cold start.
    //[[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"ShowOnboarding"];
    //[[NSUserDefaults standardUserDefaults] synchronize];

    // Ensure toc show/hide animation scales the web view w/o vertical motion.
    BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];
    self.webView.scrollView.layer.anchorPoint = CGPointMake((isRTL ? 1.0 : 0.0), 0.0);

    [self tocUpdateViewLayout];

    [self.KVOControllerNonRetaining observe:self.webView.scrollView
                                    keyPath:WMF_SAFE_KEYPATH(UIScrollView.new, contentSize)
                                    options:NSKeyValueObservingOptionNew
                                      block:^(WebViewController* observer, id object, NSDictionary* change) {
        // Restrict the web view from scrolling horizonally.
        [object preventHorizontalScrolling];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editSection:)
                                                 name:@"EditSection"
                                               object:nil];
}

- (void)editSection:(NSNotification*)notification {
    if ([self tocDrawerIsOpen]) {
        [self tocHide];
        return;
    }

    if (self.editable) {
        WMFTitleOverlayLabel* sender = notification.object;
        [self showSectionEditorForSection:[sender sectionId]];
    } else {
        ProtectedEditAttemptFunnel* funnel = [[ProtectedEditAttemptFunnel alloc] init];
        [funnel logProtectionStatus:[[self.protectionStatus allowedGroupsForAction:@"edit"] componentsJoinedByString:@","]];
        [self showProtectedDialog];
    }
}

- (void)jumpToFragmentIfNecessary {
    if (self.jumpToFragment && (self.jumpToFragment.length > 0)) {
        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"location.hash = '%@'", self.jumpToFragment]];
    }
}

- (void)autoScrollToLastScrollOffsetIfNecessary {
    if (!self.jumpToFragment) {
        [self.webView.scrollView setContentOffset:self.lastScrollOffset animated:NO];
    }
    [self saveWebViewScrollOffset];
}

- (void)tocUpdateViewLayout {
    CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
    CGFloat tocWidth     = [self tocGetWidthForWebViewScale:webViewScale];
    self.tocViewLeadingConstraint.constant = 0;
    self.tocViewWidthConstraint.constant   = tocWidth;
}

- (void)showAlert:(id)alertText type:(AlertType)type duration:(CGFloat)duration {
    if ([self tocDrawerIsOpen]) {
        return;
    }

    // Don't show alerts if onboarding onscreen.
    if ([self shouldShowOnboarding]) {
        return;
    }

    [super showAlert:alertText type:type duration:duration];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self doStuffOnAppear];
    [self.webView.scrollView wmf_shouldScrollToTopOnStatusBarTap:YES];
}

- (void)doStuffOnAppear {
    if ([self shouldShowOnboarding]) {
        [self showOnboarding];

        self.webView.alpha = 1.0f;
    }

    // Don't move this to viewDidLoad - this is because viewDidLoad may only get
    // called very occasionally as app suspend/resume probably doesn't cause
    // viewDidLoad to fire.
    [self downloadAssetsFilesIfNecessary];

    [self performHousekeepingIfNecessary];

    //[self.view randomlyColorSubviews];
}

- (BOOL)shouldShowOnboarding {
    NSNumber* showOnboarding = [[NSUserDefaults standardUserDefaults] objectForKey:@"ShowOnboarding"];
    return showOnboarding.boolValue;
}

- (void)showOnboarding {
    [self presentViewController:[OnboardingViewController wmf_initialViewControllerFromClassStoryboard] animated:YES completion:nil];
    [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"ShowOnboarding"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)performHousekeepingIfNecessary {
    NSDate* lastHousekeepingDate        = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastHousekeepingDate"];
    NSInteger daysSinceLastHouseKeeping = [[NSDate date] daysAfterDate:lastHousekeepingDate];
    //NSLog(@"daysSinceLastHouseKeeping = %ld", (long)daysSinceLastHouseKeeping);
    if (daysSinceLastHouseKeeping > 1) {
        //NSLog(@"Performing housekeeping...");
        DataHousekeeping* dataHouseKeeping = [[DataHousekeeping alloc] init];
        [dataHouseKeeping performHouseKeeping];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastHousekeepingDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    if ([self shouldShowOnboarding]) {
        self.webView.alpha = 0.0f;
    }

    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:animated];

    self.referencesHidden = YES;

    [self updateTOCButtonVisibility];
}

- (void)updateTOCButtonVisibility {
    self.buttonTOC.enabled = ![SessionSingleton sharedInstance].currentArticle.isMain;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self tocHideWithDuration:TOC_TOGGLE_ANIMATION_DURATION];

    [[QueuesSingleton sharedInstance].zeroRatedMessageFetchManager.operationQueue cancelAllOperations];

    [super viewWillDisappear:animated];
}

#pragma mark Sync config/ios.json if necessary

- (void)downloadAssetsFilesIfNecessary {
    // Sync config/ios.json at most once per day.
    [[QueuesSingleton sharedInstance].assetsFetchManager.operationQueue cancelAllOperations];

    (void)[[AssetsFileFetcher alloc] initAndFetchAssetsFileOfType:WMFAssetsFileTypeConfig
                                                      withManager:[QueuesSingleton sharedInstance].assetsFetchManager
                                                           maxAge:kWMFMaxAgeDefault];
}

#pragma mark Edit section

- (void)showSectionEditorForSection:(NSNumber*)sectionID {
    SectionEditorViewController* sectionEditVC = [SectionEditorViewController wmf_initialViewControllerFromClassStoryboard];
    sectionEditVC.section = self.session.currentArticle.sections[[sectionID integerValue]];
    [self.navigationController pushViewController:sectionEditVC animated:YES];
}

- (void)searchFieldBecameFirstResponder {
    [self tocHide];
}

#pragma mark Angle from velocity vector

- (CGFloat)getAngleInDegreesForVelocity:(CGPoint)velocity {
    // Returns angle from 0 to 360 (ccw from right)
    return (atan2(velocity.y, -velocity.x) / M_PI * 180 + 180);
}

- (CGFloat)getAbsoluteHorizontalDegreesFromVelocity:(CGPoint)velocity {
    // Returns deviation from horizontal axis in degrees.
    return (atan2(fabs(velocity.y), fabs(velocity.x)) / M_PI * 180);
}

#pragma mark Table of contents

- (BOOL)tocDrawerIsOpen {
    return !CGAffineTransformIsIdentity(self.webView.scrollView.transform);
}

- (void)tocHideWithDuration:(NSNumber*)duration {
    if ([self tocDrawerIsOpen]) {
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

        [UIView animateWithDuration:duration.floatValue
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
            self.webView.scrollView.transform = CGAffineTransformIdentity;

            self.referencesContainerView.transform = CGAffineTransformIdentity;

            self.tocViewLeadingConstraint.constant = 0;

            [self.view layoutIfNeeded];
        } completion:^(BOOL done) {
            [self.tocVC didHide];
            self.unsafeToToggleTOC = NO;
            self.webView.scrollView.contentOffset = origScrollPosition;

            [self.buttonTOC wmf_UIButton].selected = NO;

            self.webViewBottomConstraint.constant = 0;
        }];
    }
}

- (CGFloat)tocGetWebViewBottomConstraintConstant {
    /*
       When the TOC is shown, "self.webView.scrollView.transform" is changed, but this
       causes the height of the scrollView to be reduced, which doesn't mess anything up
       visually, but does cause the area beneath the scrollView to no longer respond to
       drag events.

       To reproduce the dragging deadspot issue solved by this offset:
        - set "self.webView.scrollView.layer.borderWidth = 10;"
        - comment out the line where the value returned by this method is used
        - run and open the TOC
        - notice the area beneath the border is not properly draggable

       So here we calculate the perfect bottom constraint constant to expand the "border"
       to completely encompass the vertical height of the scaled (when TOC is shown) webview.
     */
    CGFloat scale  = [self tocGetWebViewScaleWhenTOCVisible];
    CGFloat height = self.webView.scrollView.bounds.size.height;
    return (height - (height * scale)) * (1.0f / scale);
}

- (void)tocShowWithDuration:(NSNumber*)duration {
    if ([self tocDrawerIsOpen]) {
        return;
    }

    self.webViewBottomConstraint.constant = [self tocGetWebViewBottomConstraintConstant];

    self.unsafeToToggleTOC = YES;

    // Hide any alerts immediately.
    [self hideAlert];

    [self.tocVC willShow];

    [self tocUpdateViewLayout];
    [self.view layoutIfNeeded];


    [self.sectionTitlesViewController hideTopOverlay];


    [UIView animateWithDuration:duration.floatValue
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.referencesHidden = YES;

        CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
        CGAffineTransform xf = CGAffineTransformMakeScale(webViewScale, webViewScale);

        self.webView.scrollView.transform = xf;
        self.referencesContainerView.transform = xf;

        CGFloat tocWidth = [self tocGetWidthForWebViewScale:webViewScale];
        self.tocViewLeadingConstraint.constant = -tocWidth;

        [self.view layoutIfNeeded];
    } completion:^(BOOL done) {
        self.unsafeToToggleTOC = NO;
        [self.buttonTOC wmf_UIButton].selected = YES;
    }];
}

- (void)tocHide {
    if (self.unsafeToToggleTOC) {
        return;
    }

    [self tocHideWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

- (void)tocShow {
    // Prevent toc reveal if pull to refresh in effect.
    if (self.webView.scrollView.contentOffset.y < 0) {
        return;
    }

    // Prevent toc reveal if loading article.
    if (self.isFetchingArticle) {
        return;
    }

    if (!self.referencesHidden) {
        return;
    }

    if (self.session.currentArticle.isMain) {
        return;
    }

    if (self.unsafeToToggleTOC) {
        return;
    }

    [self tocShowWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

- (void)tocToggle {
    // Clear alerts
    [self fadeAlert];

    [self referencesHide];

    if ([self tocDrawerIsOpen]) {
        [self tocHide];
    } else {
        [self tocShow];
    }
}

- (BOOL)shouldPanVelocityTriggerTOC:(CGPoint)panVelocity {
    CGFloat angleFromHorizontalAxis = [self getAbsoluteHorizontalDegreesFromVelocity:panVelocity];
    if (
        (angleFromHorizontalAxis < TOC_SWIPE_TRIGGER_MAX_ANGLE)
        &&
        (fabs(panVelocity.x) > TOC_SWIPE_TRIGGER_MIN_X_VELOCITY)
        ) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    // Don't allow the web view's scroll view or the TOC's scroll view to start vertical scrolling if the
    // angle and direction of the swipe are within tolerances to trigger TOC toggle. Needed because you
    // don't want either of these to be scrolling vertically when the TOC is being revealed or hidden.
    //WHOA! see this: http://stackoverflow.com/a/18834934
    if (gestureRecognizer == self.panSwipeRecognizer) {
        if (
            (otherGestureRecognizer == self.webView.scrollView.panGestureRecognizer)
            ||
            (otherGestureRecognizer == self.tocVC.scrollView.panGestureRecognizer)
            ) {
            UIPanGestureRecognizer* otherPanRecognizer = (UIPanGestureRecognizer*)otherGestureRecognizer;
            CGPoint velocity                           = [otherPanRecognizer velocityInView:otherGestureRecognizer.view];
            if ([self shouldPanVelocityTriggerTOC:velocity]) {
                // Kill vertical scroll before it starts if we're going to show TOC.
                self.webView.scrollView.panGestureRecognizer.enabled = NO;
                self.webView.scrollView.panGestureRecognizer.enabled = YES;
                self.tocVC.scrollView.panGestureRecognizer.enabled   = NO;
                self.tocVC.scrollView.panGestureRecognizer.enabled   = YES;
            }
        }
    }
    return YES;
}

- (void)tocSetupSwipeGestureRecognizers {
    // Use pan instead for swipe so we can control speed at which swipe triggers. Idea from:
    // http://www.mindtreatstudios.com/how-its-made/ios-gesture-recognizer-tips-tricks/

    self.panSwipeRecognizer =
        [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanSwipe:)];
    self.panSwipeRecognizer.delegate               = self;
    self.panSwipeRecognizer.minimumNumberOfTouches = 1;
    [self.view addGestureRecognizer:self.panSwipeRecognizer];
}

- (void)handlePanSwipe:(UIPanGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:recognizer.view];

        if (![self shouldPanVelocityTriggerTOC:velocity] || self.webView.scrollView.isDragging) {
            return;
        }

        // Device rtl value is checked since this is what would cause the other constraints to flip.
        BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];

        if (velocity.x < 0) {
            //NSLog(@"swipe left");
            if (isRTL) {
                [self tocHide];
            } else {
                [self tocShow];
            }
        } else if (velocity.x > 0) {
            //NSLog(@"swipe right");
            if (isRTL) {
                [self tocShow];
            } else {
                [self tocHide];
            }
        }
    }
}

- (CGFloat)tocGetWebViewScaleWhenTOCVisible {
    CGFloat scale = 1.0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        scale = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.6f : 0.7f);
    } else {
        scale = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.42f : 0.55f);
    }

    // Adjust scale so it won't result in fractional pixel width when applied to web view width.
    // This prevents the web view from jumping a bit w/long pages.
    NSInteger i        = (NSInteger)self.view.frame.size.width * scale;
    CGFloat cleanScale = (i / self.view.frame.size.width);

    return cleanScale;
}

- (CGFloat)tocGetWidthForWebViewScale:(CGFloat)webViewScale {
    return self.view.frame.size.width * (1.0f - webViewScale);
}

- (CGFloat)tocGetPercentOnscreen {
    CGFloat defaultWebViewScaleWhenTOCVisible = [self tocGetWebViewScaleWhenTOCVisible];
    CGFloat defaultTOCWidth                   = [self tocGetWidthForWebViewScale:defaultWebViewScaleWhenTOCVisible];
    return 1.0f - (fabs(self.tocVC.view.frame.origin.x) / defaultTOCWidth);
}

- (BOOL)rectIntersectsWebViewTop:(CGRect)rect {
    CGFloat elementScreenYOffset =
        rect.origin.y - self.webView.scrollView.contentOffset.y + rect.size.height;
    return (elementScreenYOffset > 0) && (elementScreenYOffset < rect.size.height);
}

- (void)tocScrollWebViewToSectionWithElementId:(NSString*)elementId
                                      duration:(CGFloat)duration
                                   thenHideTOC:(BOOL)hideTOC {
    CGRect r = [self.webView getWebViewRectForHtmlElementWithId:elementId];
    if (CGRectIsNull(r)) {
        return;
    }

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

    if ([elementId isEqualToString:@"section_heading_and_content_block_0"]) {
        point = CGPointZero;
    }

    [self tocScrollWebViewToPoint:point
                         duration:duration
                      thenHideTOC:hideTOC];
}

- (void)tocScrollWebViewToPoint:(CGPoint)point
                       duration:(CGFloat)duration
                    thenHideTOC:(BOOL)hideTOC {
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        // Not using "setContentOffset:animated:" so duration of animation
        // can be controlled and action can be taken after animation completes.
        self.webView.scrollView.contentOffset = point;
    } completion:^(BOOL done) {
        // Record the new scroll location.
        [self saveWebViewScrollOffset];
        // Toggle toc.
        if (hideTOC) {
            [self tocHide];
        }
    }];
}

- (void)updateTOCScrollPositionIfVisible {
    if ([self tocDrawerIsOpen]) {
        [self.tocVC updateTOCForWebviewScrollPositionAnimated:YES];
    }
}

- (void)updateTOCScrollPositionWithoutAnimationIfHidden {
    if (![self tocDrawerIsOpen]) {
        [self.tocVC updateTOCForWebviewScrollPositionAnimated:NO];
    }
}

#pragma mark UIContainerViewControllerCallbacks

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return YES;
}

- (BOOL)shouldAutomaticallyForwardRotationMethods {
    return YES;
}

#pragma mark Webview obj-c to javascript bridge

- (CommunicationBridge*)bridge {
    if (!_bridge) {
        _bridge = [[CommunicationBridge alloc] initWithWebView:self.webView];

        __weak WebViewController* weakSelf = self;
        [_bridge addListener:@"linkClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {
            WebViewController* strSelf = weakSelf;
            if (!strSelf) {
                return;
            }

            NSString* href = payload[@"href"];

            if ([strSelf tocDrawerIsOpen]) {
                [strSelf tocHide];
                return;
            }

            if (!strSelf.referencesHidden) {
                [strSelf referencesHide];
            }

            if ([href wmf_isInternalLink]) {
                MWKTitle* pageTitle = [strSelf.session.currentArticleSite titleWithInternalLink:href];
                [weakSelf.delegate webViewController:weakSelf didTapOnLinkForTitle:pageTitle];
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
                    strSelf.externalUrl = href;
                    UIAlertView* dialog = [[UIAlertView alloc]
                                           initWithTitle:MWLocalizedString(@"zero-interstitial-title", nil)
                                                     message:MWLocalizedString(@"zero-interstitial-leave-app", nil)
                                                    delegate:strSelf
                                           cancelButtonTitle:MWLocalizedString(@"zero-interstitial-cancel", nil)
                                           otherButtonTitles:MWLocalizedString(@"zero-interstitial-continue", nil)
                                           , nil];
                    dialog.tag = WMFWebViewAlertZeroInterstitial;
                    [dialog show];
                } else {
                    NSURL* url = [NSURL URLWithString:href];
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
        }];

        [_bridge addListener:@"nonAnchorTouchEndedWithoutDragging" withBlock:^(NSString* messageType, NSDictionary* payload) {
            WebViewController* strSelf = weakSelf;
            if (!strSelf) {
                return;
            }

            //NSLog(@"nonAnchorTouchEndedWithoutDragging = %@", payload);

            // Tiny delay prevents menus from occasionally appearing when user swipes to reveal toc.
            [strSelf performSelector:@selector(animateTopAndBottomMenuReveal) withObject:nil afterDelay:0.05];

            // nonAnchorTouchEndedWithoutDragging is used so TOC may be hidden if user tapped, but did *not* drag.
            // Used because UIWebView is difficult to attach one-finger touch events to.
            [strSelf tocHide];

            [strSelf referencesHide];
        }];

        [_bridge addListener:@"referenceClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {
            WebViewController* strSelf = weakSelf;
            if (!strSelf) {
                return;
            }

            if ([strSelf tocDrawerIsOpen]) {
                [strSelf tocHide];
                return;
            }

            //NSLog(@"referenceClicked: %@", payload);
            [strSelf referencesShow:payload];
        }];

        /*
           [_bridge addListener:@"disambigClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {

           //NSLog(@"disambigClicked: %@", payload);

           }];

           [_bridge addListener:@"issuesClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {

           //NSLog(@"issuesClicked: %@", payload);

           }];
         */

        UIMenuItem* shareSnippet = [[UIMenuItem alloc] initWithTitle:MWLocalizedString(@"share-custom-menu-item", nil)
                                                              action:@selector(shareButtonPushed:)];
        [UIMenuController sharedMenuController].menuItems = @[shareSnippet];

        [_bridge addListener:@"imageClicked" withBlock:^(NSString* type, NSDictionary* payload) {
            WebViewController* strSelf = weakSelf;
            if (!strSelf) {
                return;
            }

            NSString* selectedImageURL = payload[@"url"];
            NSCParameterAssert(selectedImageURL.length);
            MWKImage* selectedImage = [strSelf.session.currentArticle.images largestImageVariantForURL:selectedImageURL
                                                                                            cachedOnly:NO];
            NSCParameterAssert(selectedImage);
            [strSelf presentGalleryForArticle:strSelf.session.currentArticle showingImage:selectedImage];
        }];

        self.unsafeToScroll = NO;
    }
    return _bridge;
}

/*
   #pragma mark History

   - (void)textFieldDidBeginEditing:(UITextField*)textField {
    // Ensure the web VC is the top VC.
    [self dismissViewControllerAnimated:YES completion:nil];;

    [self fadeAlert];
   }
 */

#pragma Saved Pages

- (void)toggleSavedPage {
    SavedPagesFunnel* funnel = [[SavedPagesFunnel alloc] init];
    MWKUserDataStore* store  = self.session.userDataStore;
    MWKTitle* title          = self.session.currentArticle.title;

    [store.savedPageList toggleSavedPageForTitle:title];
    [store.savedPageList save].then(^(){
        BOOL isSaved = [store.savedPageList isSaved:title];

        if (isSaved) {
            [self showPageSavedAlertMessageForTitle:self.session.currentArticle.title.text];
            [funnel logSaveNew];
        } else {
            [self fadeAlert];
            [funnel logDelete];
        }
    });
}

- (void)showPageSavedAlertMessageForTitle:(NSString*)title {
    NSParameterAssert(title.length);
    // First show saved message.
    NSString* savedMessage = MWLocalizedString(@"share-menu-page-saved", nil);

    NSMutableAttributedString* attributedSavedMessage =
        [savedMessage attributedStringWithAttributes:@{}
                                 substitutionStrings:@[title]
                              substitutionAttributes:@[@{ NSFontAttributeName: [UIFont italicSystemFontOfSize:ALERT_FONT_SIZE] }]].mutableCopy;

    CGFloat duration                  = 2.0;
    BOOL AccessSavedPagesMessageShown = [[NSUserDefaults standardUserDefaults] boolForKey:@"AccessSavedPagesMessageShown"];

    if (!AccessSavedPagesMessageShown) {
        duration = 5;
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"AccessSavedPagesMessageShown"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        NSString* accessMessage = [NSString stringWithFormat:@"\n%@", MWLocalizedString(@"share-menu-page-saved-access", nil)];

        NSDictionary* d = @{
            NSFontAttributeName: [UIFont wmf_glyphFontOfSize:ALERT_FONT_SIZE],
            NSBaselineOffsetAttributeName: @2
        };

        NSAttributedString* attributedAccessMessage =
            [accessMessage attributedStringWithAttributes:@{}
                                      substitutionStrings:@[WIKIGLYPH_W, WIKIGLYPH_HEART]
                                   substitutionAttributes:@[d, d]];


        [attributedSavedMessage appendAttributedString:attributedAccessMessage];
    }

    [self showAlert:attributedSavedMessage type:ALERT_TYPE_BOTTOM duration:duration];
}

#pragma mark Web view scroll offset recording

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self scrollViewScrollingEnded:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView {
    [self scrollViewScrollingEnded:scrollView];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView*)scrollView {
    // If user quickly scrolls web view make toc update when user lifts finger.
    // (in addition to when scroll ends)
    if (scrollView == self.webView.scrollView) {
        [self updateTOCScrollPositionIfVisible];
    }
}

- (void)scrollViewScrollingEnded:(UIScrollView*)scrollView {
    if (scrollView == self.webView.scrollView) {
        // Once we've started scrolling around don't allow the webview delegate to scroll
        // to a saved position! Super annoying otherwise.
        self.unsafeToScroll = YES;

        //[self printLiveContentLocationTestingOutputToConsole];
        //NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
        [self saveWebViewScrollOffset];

        [self updateTOCScrollPositionIfVisible];
        [self updateTOCScrollPositionWithoutAnimationIfHidden];

        self.pullToRefreshView.alpha = 0.0f;
    }
}

- (void)saveWebViewScrollOffset {
    // Don't record scroll position of "main" pages.
    if (self.session.currentArticle.isMain) {
        return;
    }

    [self.session.userDataStore.historyList savePageScrollPosition:self.webView.scrollView.contentOffset.y toPageInHistoryWithTitle:self.session.currentArticle.title];
}

#pragma mark Web view html content live location retrieval

- (void)printLiveContentLocationTestingOutputToConsole {
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

- (void)debugScrollLeadSanFranciscoArticleImageToTopLeft {
    // Awesome! Now works regarless of pinch-zoom scale!
    CGPoint p = [self.webView getWebViewCoordsForHtmlImageWithSrc:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/da/SF_From_Marin_Highlands3.jpg/280px-SF_From_Marin_Highlands3.jpg"];
    [self.webView.scrollView setContentOffset:p animated:YES];
}

#pragma mark Web view limit scroll up

- (void)keyboardDidShow:(NSNotification*)note {
    self.keyboardIsVisible = YES;
}

- (void)keyboardWillHide:(NSNotification*)note {
    self.keyboardIsVisible = NO;
}

#pragma mark Scroll hiding keyboard threshold

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    // Hide the keyboard if it was visible when the results are scrolled, but only if
    // the results have been scrolled in excess of some small distance threshold first.
    // This prevents tiny scroll adjustments, which seem to occur occasionally for some
    // reason, from causing the keyboard to hide when the user is typing on it!
    CGFloat distanceScrolled     = self.scrollViewDragBeganVerticalOffset - scrollView.contentOffset.y;
    CGFloat fabsDistanceScrolled = fabs(distanceScrolled);

    if (![self tocDrawerIsOpen]) {
        [self.sectionTitlesViewController updateTopOverlayForScrollOffsetY:scrollView.contentOffset.y];
    }

    if (self.keyboardIsVisible && fabsDistanceScrolled > HIDE_KEYBOARD_ON_SCROLL_THRESHOLD) {
        [self wmf_hideKeyboard];
        //NSLog(@"Keyboard Hidden!");
    }

    if (![self tocDrawerIsOpen]) {
        [self adjustTopAndBottomMenuVisibilityOnScroll];
        // No need to report scroll event to pull to refresh super vc if toc open.
        [super scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
    self.scrollViewDragBeganVerticalOffset = scrollView.contentOffset.y;
}

- (void)scrollViewDidScrollToTop:(UIScrollView*)scrollView {
    [self updateTOCScrollPositionIfVisible];
    [self updateTOCScrollPositionWithoutAnimationIfHidden];
    [self saveWebViewScrollOffset];
    self.scrollingToTop = NO;
}

#pragma mark Menus auto show-hide on scroll / reveal on tap

- (void)adjustTopAndBottomMenuVisibilityOnScroll {
    // This method causes the menus to hide when user scrolls down and show when they scroll up.
    if (self.webView.scrollView.isDragging && ![self tocDrawerIsOpen]) {
        CGFloat distanceScrolled  = self.scrollViewDragBeganVerticalOffset - self.webView.scrollView.contentOffset.y;
        CGFloat minPixelsScrolled = 20;

        // Reveal menus if scroll velocity is a bit fast. Point is to avoid showing the menu
        // if the user is *slowly* scrolling. This is how Safari seems to handle things.
        CGPoint scrollVelocity = [self.webView.scrollView.panGestureRecognizer velocityInView:self.view];
        if (distanceScrolled > 0) {
            // When pulling down let things scroll a bit faster before menus reveal is triggered.
            if (scrollVelocity.y < 350.0f) {
                return;
            }
        } else {
            // When pushing up set a lower scroll velocity threshold to hide menus.
            if (scrollVelocity.y > -250.0f) {
                return;
            }
        }

        if (fabs(distanceScrolled) < minPixelsScrolled) {
            return;
        }
        [self animateTopAndBottomMenuHidden:((distanceScrolled > 0) ? NO : YES)];

        [self referencesHide];
    }
}

- (void)animateTopAndBottomMenuHidden:(BOOL)hidden {
    // Don't toggle if hidden state isn't different or if it's already toggling.
    if ((self.navigationController.isNavigationBarHidden == hidden) || self.isAnimatingTopAndBottomMenuHidden) {
        return;
    }

    self.isAnimatingTopAndBottomMenuHidden = YES;

    // Queue it up so web view doesn't get blanked out.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [UIView animateWithDuration:0.12f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            // Not using the animated variant intentionally!
            [self.navigationController setNavigationBarHidden:hidden];
            [self.navigationController setToolbarHidden:hidden];
        } completion:^(BOOL done){
            self.isAnimatingTopAndBottomMenuHidden = NO;
        }];
    }];
}

- (void)animateTopAndBottomMenuReveal {
    // Toggle the menus closed on tap (only if they were showing).
    if (![self tocDrawerIsOpen]) {
        [self animateTopAndBottomMenuHidden:NO];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView*)scrollView {
    self.scrollingToTop = YES;
    [self referencesHide];

    // Called when the title bar is tapped.
    [self animateTopAndBottomMenuReveal];
    return YES;
}

#pragma mark Memory

- (void)updateHistoryDateVisitedForArticleBeingNavigatedFrom {
    // This is a quick hack to help with the natural back/forward behavior of the case
    // where you go back and forth from some master article to others.
    //
    // Proper fix might be to store more of a 'tree' structure so that we know which
    // 'leaf' to hang off of, but this works for now.
    MWKHistoryList* historyList = self.session.userDataStore.historyList;
    //NSLog(@"XXX %d", (int)historyList.length);
    if ([historyList countOfEntries] > 0) {
        [self.session.userDataStore.historyList addPageToHistoryWithTitle:self.session.currentArticle.title discoveryMethod:MWKHistoryDiscoveryMethodUnknown];
    }
}

#pragma mark - Article loading

- (WMFArticleFetcher*)articleFetcher {
    if (!_articleFetcher) {
        _articleFetcher = [[WMFArticleFetcher alloc] initWithDataStore:self.session.dataStore];
    }

    return _articleFetcher;
}

- (void)reloadCurrentArticleFromNetwork {
    [self reloadCurrentArticleOrMainPageWithMethod:MWKHistoryDiscoveryMethodReloadFromNetwork];
}

- (void)reloadCurrentArticleFromCache {
    [self reloadCurrentArticleOrMainPageWithMethod:MWKHistoryDiscoveryMethodReloadFromCache];
}

- (void)reloadCurrentArticleOrMainPageWithMethod:(MWKHistoryDiscoveryMethod)method {
    MWKTitle* page = self.session.currentArticle.title;
    if (page) {
        [self navigateToPage:page discoveryMethod:method];
    } else {
        [self loadTodaysArticle];
    }
}

- (void)navigateToPage:(MWKTitle*)title
       discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    NSString* cleanTitle = title.text;
    NSParameterAssert(cleanTitle.length);

    if ([title.text length] == 0) {
        [self showAlert:MWLocalizedString(@"article-unable-to-load-article", nil) type:ALERT_TYPE_TOP duration:2];
        return;
    }

    //Force view to load if not already on screen
    //We need to get HTML load process going even before we are in the view hierarchy
    if (!self.isViewLoaded) {
        [self view];
    }

    [self wmf_hideKeyboard];

    [self cancelSearchLoading];

    if (discoveryMethod != MWKHistoryDiscoveryMethodBackForward && discoveryMethod != MWKHistoryDiscoveryMethodReloadFromNetwork && discoveryMethod != MWKHistoryDiscoveryMethodReloadFromCache) {
        [self updateHistoryDateVisitedForArticleBeingNavigatedFrom];
    }

    MWKArticle* article = [self.session.dataStore articleWithTitle:title];

    self.jumpToFragment                        = title.fragment;
    self.currentTitle                          = title;
    self.session.currentArticle                = article;
    self.session.currentArticleDiscoveryMethod = discoveryMethod;

    BOOL needsRefresh = NO;
    switch (self.session.currentArticleDiscoveryMethod) {
        case MWKHistoryDiscoveryMethodSearch:
        case MWKHistoryDiscoveryMethodRandom:
        case MWKHistoryDiscoveryMethodLink:
        case MWKHistoryDiscoveryMethodReloadFromNetwork:
        case MWKHistoryDiscoveryMethodUnknown: {
            needsRefresh = YES;
            break;
        }

        case MWKHistoryDiscoveryMethodSaved:
        case MWKHistoryDiscoveryMethodBackForward:
        case MWKHistoryDiscoveryMethodReloadFromCache: {
            needsRefresh = NO;
            break;
        }
    }

    if ([article isCached] && !needsRefresh) {
        [self displayArticle:self.session.currentArticle.title];
        [self fadeAlert];
        return;
    }

    [self loadArticleWithTitleFromNetwork:title];
}

- (void)scrollToFragment:(NSString*)fragment {
    self.jumpToFragment = fragment;
    [self jumpToFragmentIfNecessary];
}

- (void)cancelArticleLoading {
//    [self.articleFetcher cancelCurrentFetch];
}

- (void)cancelSearchLoading {
    [[QueuesSingleton sharedInstance].searchResultsFetchManager.operationQueue cancelAllOperations];
}

- (void)loadArticleWithTitleFromNetwork:(MWKTitle*)title {
    NSParameterAssert(title);
    if ([title.text length] == 0) {
        [self showAlert:MWLocalizedString(@"article-unable-to-load-article", nil) type:ALERT_TYPE_TOP duration:2];
        return;
    }

    [self showProgressViewAnimated:YES];
    self.isFetchingArticle = YES;

    [self.articleFetcher fetchArticleForPageTitle:title progress:^(CGFloat progress){
        [self updateProgress:[self totalProgressWithArticleFetcherProgress:progress] animated:YES completion:NULL];
    }].then(^(MWKArticle* article){
        [self handleFetchedArticle:article];
    }).catch(^(NSError* error){
        [self handleFetchArticleError:error];
    });
}

- (void)handleFetchedArticle:(MWKArticle*)article {
    self.isFetchingArticle = NO;

    [self displayArticle:article.title];

    [self hideAlert];
}

- (void)handleFetchArticleError:(NSError*)error {
    MWKTitle* redirect = [[error userInfo] wmf_redirectTitle];

    if (redirect) {
        [self handleRedirectForTitle:redirect];
    } else {
        self.isFetchingArticle = NO;

        [self displayArticle:self.session.currentArticle.title];

        NSString* errorMsg = error.localizedDescription;
        [self showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];
    }
}

- (void)handleRedirectForTitle:(MWKTitle*)title {
    MWKHistoryEntry* history                  = [self.session.userDataStore.historyList entryForTitle:title];
    MWKHistoryDiscoveryMethod discoveryMethod =
        (history) ? history.discoveryMethod : MWKHistoryDiscoveryMethodSearch;

    [self navigateToPage:title discoveryMethod:discoveryMethod];
}

#pragma mark - FetchFinishedDelegate

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error {
    if ([sender isKindOfClass:[WikipediaZeroMessageFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
            {
                NSDictionary* banner = (NSDictionary*)fetchedData;
                if (banner) {
//TODO: use this notification to update the search box's placeholder text when zero rated
//                    TopMenuTextFieldContainer* textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
//                    textFieldContainer.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text-zero", nil);



                    //[self showAlert:title type:ALERT_TYPE_TOP duration:2];
                    NSString* title = banner[@"message"];
                    self.zeroStatusLabel.text            = title;
                    self.zeroStatusLabel.padding         = UIEdgeInsetsMake(3, 10, 3, 10);
                    self.zeroStatusLabel.textColor       = banner[@"foreground"];
                    self.zeroStatusLabel.backgroundColor = banner[@"background"];

                    [self promptFirstTimeZeroOnWithTitleIfAppropriate:title];
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
    } else if ([sender isKindOfClass:[RandomArticleFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                NSString* title = (NSString*)fetchedData;
                if (title) {
                    MWKTitle* pageTitle = [[SessionSingleton sharedInstance].currentArticleSite titleWithString:title];
                    [self navigateToPage:pageTitle discoveryMethod:MWKHistoryDiscoveryMethodRandom];
                }
            }
            break;
            case FETCH_FINAL_STATUS_CANCELLED:
                break;
            case FETCH_FINAL_STATUS_FAILED:
                //[self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                break;
        }
    }
}

#pragma mark Display article from data store

- (void)displayArticle:(MWKTitle*)title {
    NSParameterAssert(title.text);
    if ([title.text length] == 0) {
        [self showAlert:MWLocalizedString(@"article-unable-to-load-article", nil) type:ALERT_TYPE_TOP duration:2];
        return;
    }

    MWKArticle* article = [self.session.dataStore articleWithTitle:title];
    self.session.currentArticle = article;

    if (![article isCached]) {
        [self hideProgressViewAnimated:YES];
        return;
    }

    switch (self.session.currentArticleDiscoveryMethod) {
        case MWKHistoryDiscoveryMethodSaved:
        case MWKHistoryDiscoveryMethodSearch:
        case MWKHistoryDiscoveryMethodRandom:
        case MWKHistoryDiscoveryMethodLink:
        case MWKHistoryDiscoveryMethodReloadFromNetwork:
        case MWKHistoryDiscoveryMethodUnknown: {
            // Update the history so the most recently viewed article appears at the top.
            [self.session.userDataStore.historyList addPageToHistoryWithTitle:title discoveryMethod:self.session.currentArticleDiscoveryMethod];
            break;
        }

        case MWKHistoryDiscoveryMethodReloadFromCache:
        case MWKHistoryDiscoveryMethodBackForward:
            // Traversing history should not alter it, and should be served from the cache.
            break;
    }


    MWLanguageInfo* languageInfo = [MWLanguageInfo languageInfoForCode:title.site.language];
    NSString* uidir              = ([WikipediaAppUtils isDeviceLanguageRTL] ? @"rtl" : @"ltr");

    self.editable         = article.editable;
    self.protectionStatus = article.protection;

    [self updateBottomBarButtonsEnabledState];

    [self updateTOCButtonVisibility];

    NSMutableArray* sectionTextArray = [[NSMutableArray alloc] init];

    for (MWKSection* section in self.session.currentArticle.sections) {
        NSString* html = nil;

        @try {
            html = section.text;
        }@catch (NSException* exception) {
            NSAssert(html, @"html was not created from section %@: %@", section.title, section.text);
        }

        if (!html) {
            html = MWLocalizedString(@"article-unable-to-load-section", nil);;
        }

        // Structural html added around section html just before display.
        NSString* sectionHTMLWithID = [section displayHTML:html];
        [sectionTextArray addObject:sectionHTMLWithID];
    }

    if (self.session.currentArticleDiscoveryMethod == MWKHistoryDiscoveryMethodSaved ||
        self.session.currentArticleDiscoveryMethod == MWKHistoryDiscoveryMethodBackForward ||
        self.session.currentArticleDiscoveryMethod == MWKHistoryDiscoveryMethodReloadFromNetwork ||
        self.session.currentArticleDiscoveryMethod == MWKHistoryDiscoveryMethodReloadFromCache) {
        MWKHistoryEntry* historyEntry = [self.session.userDataStore.historyList entryForTitle:article.title];
        CGPoint scrollOffset          = CGPointMake(0, historyEntry.scrollPosition);
        self.lastScrollOffset = scrollOffset;
    } else {
        CGPoint scrollOffset = CGPointMake(0, 0);
        self.lastScrollOffset = scrollOffset;
    }

    // Join article sections text
    NSString* joint   = @"";     //@"<div style=\"height:20px;\"></div>";
    NSString* htmlStr = [sectionTextArray componentsJoinedByString:joint];

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

    [self.bridge loadHTML:htmlStr withAssetsFile:@"index.html"];

    // NSLog(@"languageInfo = %@", languageInfo.code);
    [self.bridge sendMessage:@"setLanguage"
                 withPayload:@{
         @"lang": languageInfo.code,
         @"dir": languageInfo.dir,
         @"uidir": uidir
     }];

    if (!self.editable) {
        [self.bridge sendMessage:@"setPageProtected" withPayload:@{}];
    }

    if ([self tocDrawerIsOpen]) {
        [self tocHide];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateProgress:0.85 animated:YES completion:NULL];
    });
}

- (void)updateBottomBarButtonsEnabledState {
    self.buttonLanguages.enabled            = !(self.session.currentArticle.isMain && [self.session.currentArticle languagecount] > 0);
    [self.buttonSave wmf_UIButton].selected = [self isCurrentArticleSaved];
}

- (BOOL)isCurrentArticleSaved {
    return [self.session.userDataStore.savedPageList isSaved:self.session.currentArticle.title];
}

#pragma mark Scroll to last section after rotate

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSString* js = @"(function() {"
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self tocUpdateViewLayout];

    [self scrollToElementOnScreenBeforeRotate];
}

- (void)scrollToElementOnScreenBeforeRotate {
    NSString* js = @"(function() {"
                   @"    if (_topElement) {"
                   @"    if (_topElement.id && (_topElement.id === 'lead_image_div')) return 0;"
                   @"        var rect = _topElement.getBoundingClientRect();"
                   @"        return (window.scrollY + rect.top) - (%f * rect.height);"
                   @"    } else {"
                   @"        return 0;"
                   @"    }"
                   @"})()";
    NSString* js2         = [NSString stringWithFormat:js, self.relativeScrollOffsetBeforeRotate, self.relativeScrollOffsetBeforeRotate];
    int finalScrollOffset = [[self.webView stringByEvaluatingJavaScriptFromString:js2] intValue];

    CGPoint point = CGPointMake(0, finalScrollOffset);

    [self tocScrollWebViewToPoint:point
                         duration:0
                      thenHideTOC:NO];
}

#pragma mark Wikipedia Zero handling

- (void)zeroStateChanged:(NSNotification*)notification {
    [[QueuesSingleton sharedInstance].zeroRatedMessageFetchManager.operationQueue cancelAllOperations];

    if ([[[notification userInfo] objectForKey:@"state"] boolValue]) {
        (void)[[WikipediaZeroMessageFetcher alloc] initAndFetchMessageForDomain:self.session.currentArticleSite.language
                                                                    withManager:[QueuesSingleton sharedInstance].zeroRatedMessageFetchManager
                                                             thenNotifyDelegate:self];
    } else {
//TODO: use this notification to update the search box's placeholder text when zero rated
//        TopMenuTextFieldContainer* textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
//        textFieldContainer.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text", nil);



        NSString* warnVerbiage = MWLocalizedString(@"zero-charged-verbiage", nil);

        CGFloat duration = 5.0f;

        //[self showAlert:warnVerbiage type:ALERT_TYPE_TOP duration:duration];
        self.zeroStatusLabel.text            = warnVerbiage;
        self.zeroStatusLabel.backgroundColor = [UIColor redColor];
        self.zeroStatusLabel.textColor       = [UIColor whiteColor];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.zeroStatusLabel.text = @"";
            self.zeroStatusLabel.padding = UIEdgeInsetsZero;
        });

        [self promptZeroOff];
    }
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case WMFWebViewAlertZeroCharged:
        case WMFWebViewAlertZeroWebPage:
            if (1 == buttonIndex) {
                NSURL* url = [NSURL URLWithString:self.wikipediaZeroLearnMoreExternalUrl];
                [[UIApplication sharedApplication] openURL:url];
            }
            break;
        case WMFWebViewAlertZeroInterstitial:
            if (1 == buttonIndex) {
                NSURL* url = [NSURL URLWithString:self.externalUrl];
                [[UIApplication sharedApplication] openURL:url];
            }
            break;
    }
}

- (UIScrollView*)refreshScrollView {
    return self.webView.scrollView;
}

- (NSString*)refreshPromptString {
    return MWLocalizedString(@"article-pull-to-refresh-prompt", nil);
}

- (NSString*)refreshRunningString {
    return MWLocalizedString(@"article-pull-to-refresh-is-refreshing", nil);
}

- (void)refreshWasPulled {
    [self reloadCurrentArticleFromNetwork];
}

- (BOOL)refreshShouldShow {
    return YES;
//    return (![self tocDrawerIsOpen])
//           &&
//           (self.session.currentArticle != nil)
//           &&
//           (!ROOT.isAnimatingTopAndBottomMenuHidden);
}

#pragma mark Bottom menu bar

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"BottomMenuViewController_embed2"]) {
        self.bottomMenuViewController = (BottomMenuViewController*)[segue destinationViewController];
    }

    if ([segue.identifier isEqualToString:@"TOCViewController_embed"]) {
        self.tocVC       = (TOCViewController*)[segue destinationViewController];
        self.tocVC.webVC = self;
    }
}

- (void)showProtectedDialog {
    UIAlertView* alert = [[UIAlertView alloc] init];
    alert.title   = MWLocalizedString(@"page_protected_can_not_edit_title", nil);
    alert.message = MWLocalizedString(@"page_protected_can_not_edit", nil);
    [alert addButtonWithTitle:@"OK"];
    alert.cancelButtonIndex = 0;
    [alert show];
}

#pragma mark Refs

- (void)setReferencesHidden:(BOOL)referencesHidden {
    if (self.referencesHidden == referencesHidden) {
        return;
    }

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

- (void)updateReferencesHeightAndBottomConstraints {
    CGFloat refsHeight = [self getRefsPanelHeight];
    self.referencesContainerViewBottomConstraint.constant = self.referencesHidden ? refsHeight : 0.0;
    self.referencesContainerViewHeightConstraint.constant = refsHeight;
}

- (CGFloat)getRefsPanelHeight {
    CGFloat percentOfHeight = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.4 : 0.6;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        percentOfHeight *= 0.5;
    }
    NSNumber* refsHeight = @((self.view.frame.size.height * MENUS_SCALE_MULTIPLIER) * percentOfHeight);
    return (CGFloat)refsHeight.integerValue;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Reminder: do tocHideWithDuration in willRotateToInterfaceOrientation, not here
    // (even though it makes the toc animate offscreen nicely if it was onscreen) as
    // it messes up in rtl langs for some reason, blanking out the screen.
    //[self tocHideWithDuration:@0.0f];

    [self updateReferencesHeightAndBottomConstraints];
}

- (BOOL)didFindReferencesInPayload:(NSDictionary*)payload {
    NSArray* refs = payload[@"refs"];
    if (!refs || (refs.count == 0)) {
        return NO;
    }
    if (refs.count == 1) {
        NSString* firstRef = refs[0];
        if ([firstRef isEqualToString:@""]) {
            return NO;
        }
    }
    return YES;
}

- (void)referencesShow:(NSDictionary*)payload {
    if (!self.referencesHidden) {
        self.referencesVC.panelHeight = [self getRefsPanelHeight];
        self.referencesVC.payload     = payload;
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

    self.referencesVC = [ReferencesVC wmf_initialViewControllerFromClassStoryboard];

    self.referencesVC.webVC = self;
    [self addChildViewController:self.referencesVC];
    self.referencesVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.referencesContainerView addSubview:self.referencesVC.view];

    [self.referencesContainerView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                             options:0
                                             metrics:nil
                                               views:@{ @"view": self.referencesVC.view }]];
    [self.referencesContainerView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                             options:0
                                             metrics:nil
                                               views:@{ @"view": self.referencesVC.view }]];

    [self.referencesVC didMoveToParentViewController:self];

    [self.referencesContainerView layoutIfNeeded];

    self.referencesVC.panelHeight = [self getRefsPanelHeight];
    self.referencesVC.payload     = payload;

    [UIView animateWithDuration:0.16
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.referencesHidden = NO;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)referencesHide {
    if (self.referencesHidden) {
        return;
    }
    [UIView animateWithDuration:0.16
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.referencesHidden = YES;

        [self.view layoutIfNeeded];
    } completion:^(BOOL done) {
        [self.referencesVC willMoveToParentViewController:nil];
        [self.referencesVC.view removeFromSuperview];
        [self.referencesVC removeFromParentViewController];
        self.referencesVC = nil;
    }];
}

#pragma mark - Progress

- (WMFProgressLineView*)progressView {
    if (!_progressView) {
        WMFProgressLineView* progress = [[WMFProgressLineView alloc] initWithFrame:CGRectZero];
        _progressView = progress;
    }

    return _progressView;
}

- (void)showProgressViewAnimated:(BOOL)animated {
    self.progressView.progress = 0.0;

    if (!animated) {
        [self _showProgressView];
        return;
    }

    [UIView animateWithDuration:0.25 animations:^{
        [self _showProgressView];
    } completion:^(BOOL finished) {
    }];
}

- (void)_showProgressView {
    self.progressView.alpha = 1.0;

    if (!self.progressView.superview) {
        [self.view addSubview:self.progressView];
        [self.progressView mas_makeConstraints:^(MASConstraintMaker* make) {
            make.top.equalTo(self.view.mas_top).with.offset(0);
            make.left.equalTo(self.view.mas_left);
            make.right.equalTo(self.view.mas_right);
            make.height.equalTo(@2.0);
        }];
    }
}

- (void)hideProgressViewAnimated:(BOOL)animated {
    if (!animated) {
        [self _hideProgressView];
        return;
    }

    [UIView animateWithDuration:0.25 animations:^{
        [self _hideProgressView];
    } completion:^(BOOL finished) {
    }];
}

- (void)_hideProgressView {
    self.progressView.alpha = 0.0;
}

- (void)updateProgress:(CGFloat)progress animated:(BOOL)animated completion:(dispatch_block_t)completion {
    [self.progressView setProgress:progress animated:animated completion:completion];
}

- (CGFloat)totalProgressWithArticleFetcherProgress:(CGFloat)progress {
    return 0.75 * progress;
}

#pragma mark - Sharing

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(shareSnippet:)) {
        if ([self.selectedText isEqualToString:@""]) {
            return NO;
        }
        [self textWasHighlighted];
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

- (NSString*)selectedText {
    NSString* selectedText =
        [[self.webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"] wmf_shareSnippetFromText];
    return selectedText.length < kMinimumTextSelectionLength ? @"" : selectedText;
}

- (void)textWasHighlighted {
    if (!self.shareFunnel) {
        self.shareFunnel = [[WMFShareFunnel alloc] initWithArticle:[SessionSingleton sharedInstance].currentArticle];
        [self.shareFunnel logHighlight];
    }
}

- (void)shareButtonPushed:(id)sender {
    [self shareSnippet:self.selectedText];
}

- (void)shareUpArrowButtonPushed {
    [self shareSnippet:self.selectedText];
}

- (void)shareSnippet:(NSString*)snippet {
    [self.webView wmf_suppressSelection];

    self.shareOptionsViewController =
        [[WMFShareOptionsViewController alloc] initWithMWKArticle:[SessionSingleton sharedInstance].currentArticle
                                                          snippet:snippet
                                                   backgroundView:self.navigationController.view
                                                         delegate:self];
}

- (void)editHistoryButtonPushed {
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:[PageHistoryViewController wmf_initialViewControllerFromClassStoryboard]];
    [self presentViewController:nc animated:YES completion:nil];
}

#pragma mark - ShareTapDelegate methods
- (void)didShowSharePreviewForMWKArticle:(MWKArticle*)article withText:(NSString*)text {
    if (!self.shareFunnel) {
        self.shareFunnel = [[WMFShareFunnel alloc] initWithArticle:article];
    }
    [self.shareFunnel logShareButtonTappedResultingInSelection:text];
}

- (void)tappedBackgroundToAbandonWithText:(NSString*)text {
    [self.shareFunnel logAbandonedAfterSeeingShareAFact];
    [self releaseShareResources];
}

- (void)tappedShareCardWithText:(NSString*)text {
    [self.shareFunnel logShareAsImageTapped];
}

- (void)tappedShareTextWithText:(NSString*)text {
    [self.shareFunnel logShareAsTextTapped];
}

- (void)finishShareWithActivityItems:(NSArray*)activityItems text:(NSString*)text {
    UIActivityViewController* shareActivityVC =
        [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                          applicationActivities:@[] /*shareMenuSavePageActivity*/ ];
    NSMutableArray* exclusions = @[
        UIActivityTypePrint,
        UIActivityTypeAssignToContact,
        UIActivityTypeSaveToCameraRoll
    ].mutableCopy;

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        [exclusions addObject:UIActivityTypeAirDrop];
        [exclusions addObject:UIActivityTypeAddToReadingList];
    }

    shareActivityVC.excludedActivityTypes = exclusions;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:shareActivityVC animated:YES completion:nil];
    } else {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:shareActivityVC];
        [self.popover presentPopoverFromBarButtonItem:self.buttonShare
                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                             animated:YES];
    }

    [shareActivityVC setCompletionHandler:^(NSString* activityType, BOOL completed) {
        if (completed) {
            [self.shareFunnel logShareSucceededWithShareMethod:activityType];
        } else {
            [self.shareFunnel logShareFailedWithShareMethod:activityType];
        }
        [self releaseShareResources];
    }];
}

- (void)releaseShareResources {
    self.shareFunnel                = nil;
    self.shareOptionsViewController = nil;
}

#pragma mark - Article loading convenience

- (void)loadRandomArticle {
    [[QueuesSingleton sharedInstance].articleFetchManager.operationQueue cancelAllOperations];

    (void)[[RandomArticleFetcher alloc] initAndFetchRandomArticleForDomain:[SessionSingleton sharedInstance].currentArticleSite.language
                                                               withManager:[QueuesSingleton sharedInstance].articleFetchManager
                                                        thenNotifyDelegate:self];
}

- (void)loadTodaysArticle {
    [self.siteInfoFetcher fetchInfoForSite:[[SessionSingleton sharedInstance] searchSite]
                                   success:^(MWKSiteInfo* siteInfo) {
        [self navigateToPage:siteInfo.mainPageTitle
             discoveryMethod:MWKHistoryDiscoveryMethodSearch];
    } failure:^(NSError* error) {
        if ([error.domain isEqual:NSURLErrorDomain]
            && error.code == NSURLErrorCannotFindHost) {
            [self showLanguages];
        } else {
            [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:2.0];
        }
    }];
}

- (MWKSiteInfoFetcher*)siteInfoFetcher {
    if (!_siteInfoFetcher) {
        _siteInfoFetcher = [MWKSiteInfoFetcher new];
        /*
           HAX: Force this particular site info fetcher to share the article operation queue. This allows for the
           cancellation of site info requests when going to the main page, e.g. when clicking a link after clicking
           "Today" in the main menu.

           This is done here and not for all site info fetchers to prevent unintended side effects.
         */
        _siteInfoFetcher.requestManager.operationQueue =
            [[[QueuesSingleton sharedInstance] articleFetchManager] operationQueue];
    }
    return _siteInfoFetcher;
}

#pragma mark - Language variant loading

- (void)showLanguages {
    LanguagesViewController* languagesVC = [LanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    languagesVC.downloadLanguagesForCurrentArticle = YES;
    languagesVC.languageSelectionDelegate          = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:nil];
}

- (void)languageSelected:(MWKLanguageLink*)langData sender:(LanguagesViewController*)sender {
    [self navigateToPage:langData.title
         discoveryMethod:MWKHistoryDiscoveryMethodSearch];

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Wikipedia Zero alert dialogs

- (void)promptFirstTimeZeroOnWithTitleIfAppropriate:(NSString*)title {
    if (![SessionSingleton sharedInstance].zeroConfigState.zeroOnDialogShownOnce) {
        [[SessionSingleton sharedInstance].zeroConfigState setZeroOnDialogShownOnce];
        self.wikipediaZeroLearnMoreExternalUrl = MWLocalizedString(@"zero-webpage-url", nil);
        UIAlertView* dialog = [[UIAlertView alloc]
                               initWithTitle:title
                                         message:MWLocalizedString(@"zero-learn-more", nil)
                                        delegate:self
                               cancelButtonTitle:MWLocalizedString(@"zero-learn-more-no-thanks", nil)
                               otherButtonTitles:MWLocalizedString(@"zero-learn-more-learn-more", nil)
                               , nil];
        dialog.tag = WMFWebViewAlertZeroWebPage;
        [dialog show];
    }
}

- (void)promptZeroOff {
    UIAlertView* dialog = [[UIAlertView alloc]
                           initWithTitle:MWLocalizedString(@"zero-charged-verbiage", nil)
                                     message:MWLocalizedString(@"zero-charged-verbiage-extended", nil)
                                    delegate:self
                           cancelButtonTitle:MWLocalizedString(@"zero-learn-more-no-thanks", nil)
                           otherButtonTitles:nil
                           , nil];
    dialog.tag = WMFWebViewAlertZeroCharged;
    [dialog show];
}

#pragma mark - WMFArticleWebViewTransitioning

- (NSUInteger)selectedSectionIndexForTransition:(WMFArticleWebViewTransition*)transition {
    //Calculate the current section
    NSInteger indexOfFirstOnscreenSection =
        [self.webView getIndexOfTopOnScreenElementWithPrefix:@"section_heading_and_content_block_"
                                                       count:[[SessionSingleton sharedInstance].currentArticle.sections count]];
    return indexOfFirstOnscreenSection;
}

- (UIView*)viewForTransition:(WMFArticleWebViewTransition*)transition {
    return self.view;
}

- (UIView*)transition:(WMFArticleWebViewTransition*)transition viewForSectionIndex:(NSUInteger)index {
    return [self.sectionTitlesViewController topHeader];
}

@end
