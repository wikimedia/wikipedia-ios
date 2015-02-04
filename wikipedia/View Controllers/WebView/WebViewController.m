//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewController_Private.h"

NSString* const WebViewControllerTextWasHighlighted = @"textWasSelected";
NSString* const WebViewControllerWillShareNotification = @"SelectionShare";
NSString* const WebViewControllerShareBegin = @"beginShare";
NSString* const WebViewControllerShareSelectedText = @"selectedText";
NSString* const kSelectedStringJS = @"window.getSelection().toString()";

#pragma mark Internal variables

@implementation WebViewController

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

    [self setupLeadImageContainer];

    session = [SessionSingleton sharedInstance];
    
    self.bottomNavHeightConstraint.constant = CHROME_MENUS_HEIGHT;
    
    self.scrollingToTop = NO;

    [self scrollIndicatorSetup];

    self.panSwipeRecognizer = nil;

    self.zeroStatusLabel.font = [UIFont systemFontOfSize:ALERT_FONT_SIZE];
    self.zeroStatusLabel.text = @"";
    
    self.referencesVC = nil;
    
    self.sectionToEditId = 0;

    [self setupBridge];

    __weak WebViewController *weakSelf = self;
    [self.bridge addListener:@"DOMContentLoaded" withBlock:^(NSString *type, NSDictionary *payload) {
        
        [weakSelf performSelector:@selector(loadingIndicatorHide) withObject:nil afterDelay:0.22f];
        [weakSelf.tocVC centerCellForWebViewTopMostSectionAnimated:NO];
        [weakSelf jumpToFragmentIfNecessary];
        [weakSelf performSelector:@selector(autoScrollToLastScrollOffsetIfNecessary) withObject:nil afterDelay:0.5f];

        // Show lead image!
        [weakSelf.leadImageContainer showForArticle:[SessionSingleton sharedInstance].article];
        [weakSelf.bridge sendMessage: @"setTableLocalization"
                         withPayload: @{
                                        @"string_table_infobox": MWLocalizedString(@"info-box-title", nil),
                                        @"string_table_other": MWLocalizedString(@"info-box-title", nil),
                                        @"string_table_close": MWLocalizedString(@"info-box-close-text", nil)
                                        }];

        [weakSelf.bridge sendMessage: @"collapseTables"
                         withPayload: nil];

    }];
    
    self.unsafeToScroll = NO;
    self.unsafeToToggleTOC = NO;
    self.lastScrollOffset = CGPointZero;
    
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
    
    self.bottomBarViewBottomConstraint = nil;

    self.view.backgroundColor = CHROME_COLOR;

    self.webView.scrollView.scrollsToTop = YES;
    self.tocVC.scrollView.scrollsToTop = NO;

    // Uncomment these lines only if testing onboarding!
    // These lines allow the onboarding to run on every app cold start.
    //[[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"ShowOnboarding"];
    //[[NSUserDefaults standardUserDefaults] synchronize];

    // Ensure toc show/hide animation scales the web view w/o vertical motion.
    BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];
    self.webView.scrollView.layer.anchorPoint = CGPointMake((isRTL ? 1.0 : 0.0), 0.0);

    [self tocUpdateViewLayout];
    
    [self loadingIndicatorAdd];
}

-(void)jumpToFragmentIfNecessary
{
    if (self.jumpToFragment && (self.jumpToFragment.length > 0)) {
        [self.bridge sendMessage: @"scrollToFragment"
                     withPayload: @{@"hash": self.jumpToFragment}];
    }
    self.jumpToFragment = nil;
}

-(void)autoScrollToLastScrollOffsetIfNecessary
{
    if (!self.jumpToFragment) {
        [self.webView.scrollView setContentOffset:self.lastScrollOffset animated:NO];
    }
    [self saveWebViewScrollOffset];
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

    // This is the first view that's opened when the app opens...
    // Perform any first-time data migration as needed.
    DataMigrationProgressViewController *migrationVC = [[DataMigrationProgressViewController alloc] init];
    if ([migrationVC needsMigration]) {
        migrationVC.delegate = self;
        [ROOT presentViewController:migrationVC animated:NO completion:nil];
    } else {
        [self doStuffOnAppear];
    }
}

-(void)dataMigrationProgressComplete:(DataMigrationProgressViewController *)viewController
{
    [viewController dismissViewControllerAnimated:NO completion:nil];
    [self doStuffOnAppear];
}

-(void)doStuffOnAppear
{
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
        DataHousekeeping *dataHouseKeeping = [[DataHousekeeping alloc] init];
        [dataHouseKeeping performHouseKeeping];
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

    sectionEditVC.section = session.article.sections[self.sectionToEditId];

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
                             [tocButton.label setWikiText: WIKIGLYPH_TOC_COLLAPSED
                                                    color: tocButton.label.color
                                                     size: tocButton.label.size
                                           baselineOffset: tocButton.label.baselineOffset];

                             self.webViewBottomConstraint.constant = 0;
                         }];
    }
}

-(void)tocShowWithDuration:(NSNumber *)duration
{
    if ([self tocDrawerIsOpen]) return;


    // When the TOC is shown, the self.webView.scrollView.transform is changed, but this
    // causes the height of the scrollView to be reduced, which doesn't mess anything up
    // visually, but does cause the area beneath the scrollView to no longer respond to
    // drag events. Turn on border for scrollView to see this (and comment out call
    // webViewBottomConstraint adjustment below). So here the web view's bottom
    // constraint is shifted down while TOC is onscreen.
    CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
    CGFloat f = self.webView.frame.size.height + (self.webView.frame.size.height * webViewScale);
    self.webViewBottomConstraint.constant = f;

    
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

                         [self.view layoutIfNeeded];
                         
                     }completion: ^(BOOL done){
                         self.unsafeToToggleTOC = NO;
                         
                         WikiGlyphButton *tocButton = [ROOT.topMenuViewController getNavBarItem:NAVBAR_BUTTON_TOC];
                         [tocButton.label setWikiText: WIKIGLYPH_TOC_EXPANDED
                                                color: tocButton.label.color
                                                 size: tocButton.label.size
                                       baselineOffset: tocButton.label.baselineOffset];
                     }];
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

    if (!session.title) return;
    if (!self.referencesHidden) return;

    if([session isCurrentArticleMain]) return;

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

    if ([elementId isEqualToString:@"section_heading_and_content_block_0"]) {
        point = CGPointZero;
    }
    
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
    }
}

#pragma mark Dealloc

-(void)dealloc
{
    [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize"];
}

#pragma mark Webview obj-c to javascript bridge

-(void)setupBridge
{
    self.bridge = [[CommunicationBridge alloc] initWithWebView:self.webView];

    __weak WebViewController *weakSelf = self;
    [self.bridge addListener:@"linkClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        WebViewController *strSelf = weakSelf;
        if (!strSelf) { return; }

        NSString *href = payload[@"href"];

        if([strSelf tocDrawerIsOpen]){
            [strSelf tocHide];
            return;
        }

        if(!strSelf.referencesHidden) [strSelf referencesHide];
        
        // @todo merge this link title extraction into MWSite
        if ([href hasPrefix:@"/wiki/"]) {

            // Ensure the menu is visible when navigating to new page.
            [strSelf animateTopAndBottomMenuReveal];
        
            MWKTitle *pageTitle = [[SessionSingleton sharedInstance].site titleWithInternalLink:href];

            [strSelf navigateToPage: pageTitle
                     discoveryMethod: MWK_DISCOVERY_METHOD_LINK
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
                strSelf.externalUrl = href;
                UIAlertView *dialog = [[UIAlertView alloc]
                                       initWithTitle:MWLocalizedString(@"zero-interstitial-title", nil)
                                       message:MWLocalizedString(@"zero-interstitial-leave-app", nil)
                                       delegate:strSelf
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
        WebViewController *strSelf = weakSelf;
        if (!strSelf) { return; }

        if([strSelf tocDrawerIsOpen]){
            [strSelf tocHide];
            return;
        }
        
        if (strSelf.editable) {
            strSelf.sectionToEditId = [payload[@"sectionId"] integerValue];
            [strSelf showSectionEditor];
        } else {
            ProtectedEditAttemptFunnel *funnel = [[ProtectedEditAttemptFunnel alloc] init];
            [funnel logProtectionStatus:[[strSelf.protectionStatus allowedGroupsForAction:@"edit"] componentsJoinedByString:@","]];
            [strSelf showProtectedDialog];
        }
    }];
    
    [self.bridge addListener:@"langClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        WebViewController *strSelf = weakSelf;
        if (!strSelf) { return; }

        if([strSelf tocDrawerIsOpen]){
            [strSelf tocHide];
            return;
        }

        NSLog(@"Language button pushed");
        [strSelf languageButtonPushed];
    }];
    
    [self.bridge addListener:@"historyClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        WebViewController *strSelf = weakSelf;
        if (!strSelf) { return; }

        if([strSelf tocDrawerIsOpen]){
            [strSelf tocHide];
            return;
        }

        [strSelf historyButtonPushed];
    }];
    
    [self.bridge addListener:@"nonAnchorTouchEndedWithoutDragging" withBlock:^(NSString *messageType, NSDictionary *payload) {
        WebViewController *strSelf = weakSelf;
        if (!strSelf) { return; }

        NSLog(@"nonAnchorTouchEndedWithoutDragging = %@", payload);

        // Tiny delay prevents menus from occasionally appearing when user swipes to reveal toc.
        [strSelf performSelector:@selector(animateTopAndBottomMenuReveal) withObject:nil afterDelay:0.05];

        // nonAnchorTouchEndedWithoutDragging is used so TOC may be hidden if user tapped, but did *not* drag.
        // Used because UIWebView is difficult to attach one-finger touch events to.
        [strSelf tocHide];

        [strSelf referencesHide];
    }];
    
    [self.bridge addListener:@"referenceClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        WebViewController *strSelf = weakSelf;
        if (!strSelf) { return; }

        if([strSelf tocDrawerIsOpen]){
            [strSelf tocHide];
            return;
        }

        //NSLog(@"referenceClicked: %@", payload);
        [strSelf referencesShow:payload];
        
    }];
    
    UIMenuItem *shareSnippet = [[UIMenuItem alloc] initWithTitle:MWLocalizedString(@"share-custom-menu-item", nil)
                                                          action:@selector(shareSnippet:)];
    [UIMenuController sharedMenuController].menuItems = @[shareSnippet];

    [self.bridge addListener:@"imageClicked" withBlock:^(NSString *type, NSDictionary *payload) {
        WebViewController *strSelf = weakSelf;
        if (!strSelf) { return; }

        NSString *selectedImageURL = payload[@"url"];
        NSCParameterAssert(selectedImageURL.length);
        MWKImage *selectedImage = [strSelf->session.article.images largestImageVariantForURL:selectedImageURL];
        NSCParameterAssert(selectedImage);
        [strSelf presentGalleryForArticle:strSelf->session.article showingImage:selectedImage];
    }];

    self.unsafeToScroll = NO;
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
    MWKTitle *title = session.title;
    MWKUserDataStore *store = session.userDataStore;
    MWKSavedPageList *list = store.savedPageList;
    MWKSavedPageEntry *entry = [list entryForTitle:title];

    SavedPagesFunnel *funnel = [[SavedPagesFunnel alloc] init];

    if (entry == nil) {
        // Show alert.
        [self showPageSavedAlertMessageForTitle:title.prefixedText];

        // Actually perform the save.
        entry = [[MWKSavedPageEntry alloc] initWithTitle:title];
        [list addEntry:entry];

        [store save];
        [funnel logSaveNew];
    } else {
        // Unsave!
        [list removeEntry:entry];
        [store save];

        [self fadeAlert];
        [funnel logDelete];
    }
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
                            NSFontAttributeName: [UIFont wmf_glyphFontOfSize:ALERT_FONT_SIZE],
                            NSBaselineOffsetAttributeName : @2
                            };
        
        NSAttributedString *attributedAccessMessage =
        [accessMessage attributedStringWithAttributes: @{}
                                  substitutionStrings: @[WIKIGLYPH_W, WIKIGLYPH_HEART]
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
    if ([session isCurrentArticleMain]) return;

    MWKHistoryEntry *entry = [session.userDataStore.historyList entryForTitle:session.title];
    if (entry) {
        entry.scrollPosition = self.webView.scrollView.contentOffset.y;
        session.userDataStore.historyList.dirty = YES; // hack to force
        [session.userDataStore save];
    }
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
    
    //DataHousekeeping *dataHouseKeeping = [[DataHousekeeping alloc] init];
    //[dataHouseKeeping performHouseKeeping];
    
    // Do not remove the following commented toggle. It's for testing W0 stuff.
    //[session.zeroConfigState toggleFakeZeroOn];

    //[self toggleImageSheet];

    //ReferencesVC *referencesVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"ReferencesVC"];
    //[self presentViewController:referencesVC animated:YES completion:^{}];

    //NSLog(@"articleFetchManager.operationCount = %lu", (unsigned long)[QueuesSingleton sharedInstance].articleFetchManager.operationQueue.operationCount);
}

#if DEBUG
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
        MWKArticle *article = session.article;
        NSMutableArray *views = @[].mutableCopy;
        for (MWKSection *section in article.sections) {
            int index = 0;
            for (MWKImage *image in section.images) {
                NSString *title = (section.line) ? section.line : article.title.prefixedText;
                //NSLog(@"\n\n\nsection image = %@ \n\tsection = %@ \n\tindex in section = %@ \n\timage size = %@", sectionImage.image.fileName, sectionTitle, sectionImage.index, sectionImage.image.dataSize);
                if(index == 0){
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
                UIImageView *imageView = [[UIImageView alloc] initWithImage:[image asUIImage]];
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                [views addObject:imageView];
                UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 5)];
                [views addObject:spacerView];
                index++;
            }
        }
        NSLog(@"%@", views);
        [NAV topActionSheetShowWithViews:views orientation:TABULAR_SCROLLVIEW_LAYOUT_HORIZONTAL];
    }else{
        [NAV topActionSheetHide];
    }
}
#endif

-(void)updateHistoryDateVisitedForArticleBeingNavigatedFrom
{
    // This is a quick hack to help with the natural back/forward behavior of the case
    // where you go back and forth from some master article to others.
    //
    // Proper fix might be to store more of a 'tree' structure so that we know which
    // 'leaf' to hang off of, but this works for now.
    MWKHistoryList *historyList = session.userDataStore.historyList;
    NSLog(@"XXX %d", (int)historyList.length);
    if (historyList.length > 0) {
        // Grab the latest
        MWKHistoryEntry *historyEntry = [historyList entryForTitle:session.title];
        if (historyEntry) {
            historyEntry.date = [NSDate date];
            [historyList addEntry:historyEntry];
            [session.userDataStore save];
        }
    }
}

#pragma mark Article loading ops

-(void)navigateToPage: (MWKTitle *)title
      discoveryMethod: (MWKHistoryDiscoveryMethod)discoveryMethod
 showLoadingIndicator: (BOOL)showLoadingIndicator
{
    NSString *cleanTitle = title.prefixedText;
    
    // Don't try to load nothing. Core data takes exception with such nonsense.
    if (cleanTitle == nil) return;
    if (cleanTitle.length == 0) return;
    
    [self hideKeyboard];
    
    if(showLoadingIndicator) [self loadingIndicatorShow];
    
    // Show loading message
    //[self showAlert:MWLocalizedString(@"search-loading-section-zero", nil) type:ALERT_TYPE_TOP duration:-1];

    self.jumpToFragment = title.fragment;

    // Update the history dateVisited timestamp of the article *presently shown* by the webView
    // only if the article to be loaded was NOT loaded via back or forward buttons. The article
    // being *navigated to* has its history dateVisited updated later in this method.
    if (discoveryMethod != MWK_DISCOVERY_METHOD_BACKFORWARD) {
        [self updateHistoryDateVisitedForArticleBeingNavigatedFrom];
        self.didLastNavigateByBackOrForward = NO;
    }else{
        self.didLastNavigateByBackOrForward = YES;
    }

    [self retrieveArticleForPageTitle: title
                      discoveryMethod: discoveryMethod];

    /*
    // Reset the search field to its placeholder text after 5 seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
        if (!textFieldContainer.textField.isFirstResponder) textFieldContainer.textField.text = @"";
    });
    */
}

-(void)reloadCurrentArticleInvalidatingCache:(BOOL)invalidateCache
{
    [self navigateToPage: session.title
         discoveryMethod: (invalidateCache ? MWK_DISCOVERY_METHOD_SEARCH : MWK_DISCOVERY_METHOD_SAVED)
    showLoadingIndicator: YES];
}

- (void)fetchFinished: (id)sender
          fetchedData: (id)fetchedData
               status: (FetchFinalStatus)status
                error: (NSError *)error
{
    if ([sender isKindOfClass:[ArticleFetcher class]]) {
        
        MWKArticle *article = session.article;
        
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
            {
                // Redirect if necessary.
                MWKTitle *redirectedTitle = article.redirected;
                if (redirectedTitle) {
                    // Get discovery method for call to "retrieveArticleForPageTitle:".
                    // There should only be a single history item (at most).
                    MWKHistoryEntry *history = [session.userDataStore.historyList entryForTitle:article.title];
                    // Get the article's discovery method.
                    MWKHistoryDiscoveryMethod discoveryMethod =
                    (history) ? history.discoveryMethod : MWK_DISCOVERY_METHOD_SEARCH;

                    // Remove the article so it doesn't get saved.
                    [session.userDataStore.historyList removeEntry:history];
                    [session.article remove];

                    // Redirect!
                    [self retrieveArticleForPageTitle: redirectedTitle
                                      discoveryMethod: discoveryMethod];
                    return;
                }

                // Update the toc and web view.
                [self.tocVC setTocSectionDataForSections:article.sections];
                [self displayArticle:article.title];


            }
                break;
            case FETCH_FINAL_STATUS_FAILED:
            {
                NSString *errorMsg = error.localizedDescription;
                [self showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];

                [self loadingIndicatorHide];

                // Remove the article so it doesn't get saved.
                //[article.managedObjectContext deleteObject:article];
                [article remove];
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
            {
                // Remove the article so it doesn't get saved.
                //[article.managedObjectContext deleteObject:article];
                [article remove];
            }
                break;

            default:
                break;
                
        }

    } else if ([sender isKindOfClass:[WikipediaZeroMessageFetcher class]]) {

        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
            {
                NSDictionary *banner = (NSDictionary*)fetchedData;
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

- (void)cancelArticleLoading
{
   [[QueuesSingleton sharedInstance].articleFetchManager.operationQueue cancelAllOperations];
}

- (void)cancelSearchLoading
{
    [[QueuesSingleton sharedInstance].searchResultsFetchManager.operationQueue cancelAllOperations];
}

- (void)retrieveArticleForPageTitle: (MWKTitle *)pageTitle
                    discoveryMethod: (MWKHistoryDiscoveryMethod)discoveryMethod
{
    // Cancel certain in-progress fetches.
    [self cancelSearchLoading];
    [self cancelArticleLoading];
    
    self.currentTitle = pageTitle;
    session.title = pageTitle;

    MWKArticle *article = session.article;
    
    switch (discoveryMethod) {
        case MWK_DISCOVERY_METHOD_SAVED:
        case MWK_DISCOVERY_METHOD_SEARCH:
        case MWK_DISCOVERY_METHOD_RANDOM:
        case MWK_DISCOVERY_METHOD_LINK:
        case MWK_DISCOVERY_METHOD_UNKNOWN:{
            // Update the history so the most recently viewed article appears at the top.
            [session.userDataStore updateHistory:article.title discoveryMethod:discoveryMethod];
            break;
        }
        
        case MWK_DISCOVERY_METHOD_BACKFORWARD:
            // Traversing history should not alter it, and should be served from the cache.
            break;
    }

    switch (discoveryMethod) {
        case MWK_DISCOVERY_METHOD_SEARCH:
        case MWK_DISCOVERY_METHOD_RANDOM:
        case MWK_DISCOVERY_METHOD_LINK:
        case MWK_DISCOVERY_METHOD_UNKNOWN:{
            // Mark article as needing refreshing so its data will be re-downloaded.
            // Reminder: this needs to happen *after* "session.title" has been updated
            // with the title of the article being retrieved. Otherwise you end up
            // marking the previous article as needing to be refreshed.
            session.article.needsRefresh = YES;
            break;
        }

        case MWK_DISCOVERY_METHOD_SAVED:
        case MWK_DISCOVERY_METHOD_BACKFORWARD:
            break;
    }

    // If article with sections just show them (unless needsRefresh is YES)
    if ([article.sections count] > 0 && !article.needsRefresh) {
        [self.tocVC setTocSectionDataForSections:session.article.sections];
        [self displayArticle:session.title];
        //[self showAlert:MWLocalizedString(@"search-loading-article-loaded", nil) type:ALERT_TYPE_TOP duration:-1];
        [self fadeAlert];
    }else{
        // "fetchFinished:" above will be notified when articleFetcher has actually retrieved some data.
        // Note: cast to void to avoid compiler warning: http://stackoverflow.com/a/7915839
        (void)[[ArticleFetcher alloc] initAndFetchSectionsForArticle: session.article
                                                         withManager: [QueuesSingleton sharedInstance].articleFetchManager
                                                  thenNotifyDelegate: self];


    }
}

#pragma mark Display article from core data

- (void)displayArticle:(MWKTitle *)title
{
    // this will reset session.articleStore
    session.title = title;

    MWKArticle *article = session.article;
    if (!article) return;

    MWLanguageInfo *languageInfo = [MWLanguageInfo languageInfoForCode:title.site.language];
    NSString *uidir = ([WikipediaAppUtils isDeviceLanguageRTL] ? @"rtl" : @"ltr");

    int langCount = article.languagecount;
    NSDate *lastModified = article.lastmodified;
    MWKUser *lastModifiedBy = article.lastmodifiedby;
    self.editable = article.editable;
    self.protectionStatus = article.protection;
    
    [self.bottomMenuViewController updateBottomBarButtonsEnabledState];
    
    [ROOT.topMenuViewController updateTOCButtonVisibility];

    NSMutableArray *sectionTextArray = [[NSMutableArray alloc] init];

    for (MWKSection *section in session.article.sections) {
        NSString *html = section.text;
        if (html) {
            // Structural html added around section html just before display.
            NSString *sectionHTMLWithID = [section displayHTML:html];

            [sectionTextArray addObject:sectionHTMLWithID];
        }
    }
    
    // If article has no thumbnailImage, use the first section image instead.
    // Actually sets article.thumbnailImage to point to the image record of the first section
    // image. That way, if the housekeeping code removes all section images, it won't remove this
    // particular one because it checks to see if an article is referencing an image before it
    // removes them.
    //[article ifNoThumbnailUseFirstSectionImageAsThumbnailUsingContext:articleDataContext_.mainContext];
    
    MWKHistoryEntry *historyEntry = [session.userDataStore.historyList entryForTitle:article.title];

    if((self.didLastNavigateByBackOrForward && historyEntry) || historyEntry.discoveryMethod == MWK_DISCOVERY_METHOD_SAVED){
        
        CGPoint scrollOffset = CGPointMake(0, historyEntry.scrollPosition);
        self.lastScrollOffset = scrollOffset;
        
    }else{
        
        CGPoint scrollOffset = CGPointMake(0, 0);
        self.lastScrollOffset = scrollOffset;
    }
    
    if (![[SessionSingleton sharedInstance] isCurrentArticleMain]) {
        [sectionTextArray addObject: [self renderFooterDivider]];
        [sectionTextArray addObject: [self renderLastModified:lastModified by:lastModifiedBy]];
        [sectionTextArray addObject: [self renderLanguageButtonForCount: langCount]];
        [sectionTextArray addObject: [self renderLicenseFooter]];
    }
    
    // This is important! Ensures bottom of web view article can be scrolled closer to the top of
    // the screen. Works in conjunction with "limitScrollUp:" method.
    // Note: had to add "px" to the height because we added "<!DOCTYPE html>" to the top
    // of the index.html - it won't actually give the div height w/o this now (no longer
    // using quirks mode now that doctype specified).
    [sectionTextArray addObject: [NSString stringWithFormat:@"<div style='height:%dpx;background-color:white;'></div>", BOTTOM_SCROLL_LIMIT_HEIGHT]];
    
    // Join article sections text
    NSString *joint = @""; //@"<div style=\"height:20px;\"></div>";
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

    [self.bridge loadHTML:htmlStr withAssetsFile:@"index.html"];

    // NSLog(@"languageInfo = %@", languageInfo.code);
    [self.bridge sendMessage: @"setLanguage"
                 withPayload: @{
                                @"lang": languageInfo.code,
                                @"dir": languageInfo.dir,
                                @"uidir": uidir
                                }];
    
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

-(NSString *)renderLastModified:(NSDate *)date by:(MWKUser *)user
{
    NSString *langCode = [[NSLocale preferredLanguages] objectAtIndex:0];
    MWLanguageInfo *lang = [MWLanguageInfo languageInfoForCode:langCode];
    NSString *dir = lang.dir;
    NSString *icon = WIKIGLYPH_PENCIL;

    NSString *ts = [WikipediaAppUtils relativeTimestamp:date];
    NSString *recent = (fabs([date timeIntervalSinceNow]) < 60*60*24) ? @"recent" : @"";
    NSString *lm;
    if (user && !user.anonymous) {
        lm = [[MWLocalizedString(@"lastmodified-by-user", nil)
               stringByReplacingOccurrencesOfString:@"$1" withString:ts]
                stringByReplacingOccurrencesOfString:@"$2" withString:user.name];
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
        (void)[[WikipediaZeroMessageFetcher alloc] initAndFetchMessageForDomain: session.site.language
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
    return (![self tocDrawerIsOpen])
        &&
        (session.article != nil)
        &&
        (!ROOT.isAnimatingTopAndBottomMenuHidden);
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
                                languagesVC.languageSelectionDelegate = self;
                            }];
}

-(void)historyButtonPushed
{
    [self performModalSequeWithID: @"modal_segue_show_page_history"
                  transitionStyle: UIModalTransitionStyleCoverVertical
                            block: nil];
}

- (void)languageSelected:(NSDictionary *)langData sender:(LanguagesViewController *)sender
{
    MWKSite *site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:langData[@"code"]];
    MWKTitle *title = [site titleWithString:langData[@"*"]];
    [NAV loadArticleWithTitle: title
                     animated: NO
              discoveryMethod: MWK_DISCOVERY_METHOD_SEARCH
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

#pragma mark Lead image container

-(void)setupLeadImageContainer
{
    self.leadImageContainer = [[[NSBundle mainBundle] loadNibNamed: @"LeadImageContainer"
                                                             owner: nil
                                                           options: nil] firstObject];

    self.leadImageContainer.delegate = self;

    [self.leadImageContainer addTarget:self
                                action:@selector(didTouchLeadImage:)
                      forControlEvents:UIControlEventTouchUpInside];

    // Because of autolayout weirdness with adding subview's to UIWebView's
    // scrollview (which is done so we'll get scroll tracking and scaling
    // when TOC appears for free), autoresizingMask is used - this also means
    // we need to manually update leadImageContainer's frame on rotate - which
    // is presently done in its "updateNonImageElements" method.
    self.leadImageContainer.autoresizingMask =
        (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth);
    
    [self.webView.scrollView addSubview:self.leadImageContainer];
    
    self.leadImageContainer.frame =
        (CGRect){{0, 0}, {self.webView.scrollView.frame.size.width, LEAD_IMAGE_CONTAINER_HEIGHT}};
}

- (void)leadImageHeightChangedTo: (NSNumber *)height
{
    // Let the html spacer div adjust to the new height of the lead image container.
    [self.bridge sendMessage: @"setLeadImageDivHeight"
                 withPayload: @{@"height": height}];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(shareSnippet:)) {
        if ([[self getSelectedtext] isEqualToString:@""]) {
            return NO;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:WebViewControllerTextWasHighlighted
                                                            object:self
                                                          userInfo:nil];
        return YES;
    }
    return [super canPerformAction:action
                        withSender:sender];
}

- (void)shareSnippet:(id)sender {
    NSString *selectedText = [self getSelectedtext];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WebViewControllerWillShareNotification
                                                        object:self
                                                      userInfo:@{WebViewControllerShareSelectedText : selectedText}];
}

- (NSString *) getSelectedtext
{
    NSString *selectedText = [self.webView stringByEvaluatingJavaScriptFromString:kSelectedStringJS];
    return selectedText.length < kMinimumTextSelectionLength ? @"" : selectedText;
}

- (void)didTouchLeadImage:(id)sender
{
    [self presentGalleryForArticle:session.article showingImage:session.article.image];
}

@end
