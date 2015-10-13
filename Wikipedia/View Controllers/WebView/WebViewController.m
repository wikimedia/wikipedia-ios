//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewController_Private.h"

#import "Wikipedia-Swift.h"

@import Masonry;
@import BlocksKit.BlocksKit_UIKit;

#import "NSString+WMFHTMLParsing.h"

#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "RandomArticleFetcher.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFArticleFetcher.h"
#import "MWKSiteInfo.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "MWKLanguageLink.h"

#import "WMFShareCardViewController.h"
#import "UIWebView+WMFSuppressSelection.h"
#import "UIView+WMFRTLMirroring.h"
#import "WMFArticleViewController.h"
#import "PageHistoryViewController.h"

#import "WMFSectionHeadersViewController.h"
#import "WMFSectionHeaderEditProtocol.h"

#import "UIWebView+WMFJavascriptContext.h"
#import "UIWebView+WMFTrackingView.h"
#import "UIWebView+ElementLocation.h"
#import "UIViewController+WMFOpenExternalUrl.h"

typedef NS_ENUM (NSInteger, WMFWebViewAlertType) {
    WMFWebViewAlertZeroWebPage,
    WMFWebViewAlertZeroCharged,
    WMFWebViewAlertZeroInterstitial
};

@interface WebViewController () <WMFSectionHeaderEditDelegate, ReferencesVCDelegate>

@property (nonatomic, strong) UIBarButtonItem* buttonEditHistory;

@property (nonatomic, strong) MASConstraint* headerHeight;
@property (nonatomic, strong) UIView* footerContainerView;

@property (nonatomic) BOOL isAnimatingTopAndBottomMenuHidden;

@property (nonatomic, strong) WMFSectionHeadersViewController* sectionHeadersViewController;

@end

@implementation WebViewController

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (void)setupBottomMenuButtons {
    @weakify(self)
    self.buttonEditHistory = [UIBarButtonItem wmf_buttonType:WMFButtonTypePencil handler:^(id sender){
        @strongify(self)
        [self editHistoryButtonPushed];
    }];

    self.toolbarItems = @[
        self.buttonEditHistory,
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
    ];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self loadHeadersAndFooters];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveWithNotification:) name:UIApplicationWillResignActiveNotification object:nil];

    
//    self.sectionHeadersViewController =
//        [[WMFSectionHeadersViewController alloc] initWithView:self.view
//                                                      webView:self.webView
//                                               topLayoutGuide:self.mas_topLayoutGuide];
//
//    self.sectionHeadersViewController.editSectionDelegate = self;

    [self.navigationController.navigationBar wmf_mirrorIfDeviceRTL];
    [self.navigationController.toolbar wmf_mirrorIfDeviceRTL];

    [self setupBottomMenuButtons];

    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;

    self.scrollingToTop = NO;

    self.panSwipeRecognizer = nil;

    self.zeroStatusLabel.font = [UIFont systemFontOfSize:ALERT_FONT_SIZE];
    self.zeroStatusLabel.text = @"";

    self.referencesVC = nil;

    __weak WebViewController* weakSelf = self;
    [self.bridge addListener:@"DOMContentLoaded" withBlock:^(NSString* type, NSDictionary* payload) {

        [weakSelf updateProgress:1.0 animated:YES completion:^{
            [weakSelf hideProgressViewAnimated:YES];
        }];

        //Need to introduce a delay here or the webview still might not be loaded. Should look at using the webview callbacks instead.
        dispatchOnMainQueueAfterDelayInSeconds(0.1, ^{
            [weakSelf autoScrollToLastScrollOffsetIfNecessary];
            [weakSelf jumpToFragmentIfNecessary];
            [weakSelf.sectionHeadersViewController resetHeaders];
        });
    }];

    self.lastScrollOffset = CGPointZero;

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

    // UIWebView has a bug which causes a black bar to appear at
    // bottom of the web view if toc quickly dragged on and offscreen.
    self.webView.opaque = NO;

    self.view.backgroundColor = CHROME_COLOR;

    [self observeWebScrollViewContentSize];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.referencesHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self doStuffOnAppear];
    [self layoutWebViewSubviews];
    [self.webView.scrollView wmf_shouldScrollToTopOnStatusBarTap:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutWebViewSubviews];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[QueuesSingleton sharedInstance].zeroRatedMessageFetchManager.operationQueue cancelAllOperations];
    [self saveWebViewScrollOffset];
    [super viewWillDisappear:animated];
}

- (void)willTransitionToTraitCollection:(UITraitCollection*)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > _Nonnull context) {
        [self layoutWebViewSubviews];
    } completion:nil];
}

#pragma mark - Observations

/**
 *  Observe changes to @c webView.scrollView.contentSize so we can recompute it and layout subviews.
 */
- (void)observeWebScrollViewContentSize {
    [self.KVOControllerNonRetaining observe:self.webView.scrollView
                                    keyPath:WMF_SAFE_KEYPATH(self.webView.scrollView, contentSize)
                                    options:NSKeyValueObservingOptionInitial
                                      block:^(WebViewController* observer, id object, NSDictionary* change) {
        [observer layoutWebViewSubviews];
    }];
}

- (void)applicationWillResignActiveWithNotification:(NSNotification*)note{
    
    [self saveWebViewScrollOffset];
}

#pragma mark - Headers & Footers

- (void)loadHeadersAndFooters {
    /*
       NOTE: Need to add headers/footers as subviews as opposed to using contentInset, due to running into the following
       issues when attempting a contentInset approach:
       - doesn't work well for footers:
       - contentInset causes jumpiness when scrolling beyond _bottom_ of content
       - interferes w/ bouncing at the bottom
       - forces you to manually set scrollView offsets
       - breaks native scrolling to top/bottom (i.e. title bar tap goes to top of content, not header)

       IOW, contentInset is nice for pull-to-refresh, parallax scrolling stuff, but not quite for table/collection-view-style
       headers & footers
     */
    [self addHeaderView];
    [self addFooterView];
}

- (void)addHeaderView {
    if (!self.headerViewController) {
        return;
    }
    [self.webView.scrollView addSubview:self.headerViewController.view];
    [self.headerViewController.view mas_makeConstraints:^(MASConstraintMaker* make) {
        // lead/trail must be constained to webview, the scrollview doesn't define a width
        make.leading.and.trailing.equalTo(self.webView);
        make.top.equalTo(self.webView.scrollView);
        self.headerHeight = make.height.equalTo(@([self headerHeightForCurrentTraitCollection]));
    }];
    [self.headerViewController didMoveToParentViewController:self];
}

- (void)addFooterView {
    [self addFooterContainerView];
    [self addFooterViews];
}

- (void)addFooterContainerView {
    self.footerContainerView = [UIView new];
    [self.webView.scrollView addSubview:self.footerContainerView];
    [self.footerContainerView mas_makeConstraints:^(MASConstraintMaker* make) {
        // lead/trail must be constained to webview, the scrollview doesn't define a width
        make.leading.and.trailing.equalTo(self.webView);
        make.top.equalTo([[self.webView wmf_browserView] mas_bottom]);
        make.bottom.equalTo(self.webView.scrollView);
    }];
}

- (void)addFooterViews {
    NSParameterAssert(self.isViewLoaded);
    [self.footerViewControllers bk_reduce:self.footerContainerView.mas_top
                                withBlock:^MASViewAttribute*(MASViewAttribute* topAnchor,
                                                             UIViewController* childVC) {
        [self.footerContainerView addSubview:childVC.view];
        [childVC.view mas_makeConstraints:^(MASConstraintMaker* make) {
            make.leading.and.trailing.equalTo(self.footerContainerView);
            make.top.equalTo(topAnchor);
        }];
        [childVC didMoveToParentViewController:self];
        return childVC.view.mas_bottom;
    }];
    [self.footerViewControllers.lastObject.view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.bottom.equalTo(self.footerContainerView);
    }];
}

- (void)setFooterViewControllers:(NSArray<UIViewController*>*)footerViewControllers {
    NSAssert(!self.footerViewControllers, @"Dynamic/re-configurable footer views is not supported.");
    NSAssert(!self.isViewLoaded, @"Expected footers to be configured before viewDidLoad.");
    _footerViewControllers = [footerViewControllers copy];
    [_footerViewControllers bk_each:^(UIViewController* childVC) {
        [self addChildViewController:childVC];
        // didMoveToParent is called when they are added to the view
    }];
}

- (void)setHeaderViewController:(UIViewController*)headerViewController {
    NSAssert(!self.headerViewController, @"Dynamic/re-configurable header view is not supported.");
    NSAssert(!self.isViewLoaded, @"Expected header to be configured before viewDidLoad.");
    _headerViewController = headerViewController;
    [self addChildViewController:self.headerViewController];
    // didMoveToParent is called when it is added to the view
}

- (void)layoutWebViewSubviews {
    [self.headerHeight setOffset:[self headerHeightForCurrentTraitCollection]];
    CGFloat headerBottom = CGRectGetMaxY(self.headerViewController.view.frame);
    /*
       HAX: need to manage positioning the browser view manually.
       using constraints seems to prevent the browser view size and scrollview contentSize from being set
       properly.
     */
    UIView* browserView = [self.webView wmf_browserView];
    [browserView setFrame:(CGRect){
         .origin = CGPointMake(0, headerBottom),
         .size = browserView.frame.size
     }];
    CGFloat readMoreHeight   = self.footerContainerView.frame.size.height;
    CGFloat totalHeight      = CGRectGetMaxY(browserView.frame) + readMoreHeight;
    CGFloat constrainedWidth = self.webView.scrollView.frame.size.width;
    CGSize requiredSize      = CGSizeMake(constrainedWidth, totalHeight);
    /*
       HAX: It's important that we restrict the contentSize to the view's width to prevent awkward horizontal scrolling.
     */
    if (!CGSizeEqualToSize(requiredSize, self.webView.scrollView.contentSize)) {
        self.webView.scrollView.contentSize = requiredSize;
    }
}

- (CGFloat)headerHeightForCurrentTraitCollection {
    return [self headerHeightForTraitCollection:self.traitCollection];
}

- (CGFloat)headerHeightForTraitCollection:(UITraitCollection*)traitCollection {
    switch (traitCollection.verticalSizeClass) {
        case UIUserInterfaceSizeClassRegular:
            return 160;
        default:
            return 0;
    }
}

#pragma mark - Utility

- (void)jumpToFragmentIfNecessary {
    if (self.jumpToFragment && (self.jumpToFragment.length > 0)) {
        CGRect r = [self.webView getScreenRectForHtmlElementWithId:self.jumpToFragment];
        if (!CGRectIsNull(r)) {
            CGPoint p = CGPointMake(
                                    self.webView.scrollView.contentOffset.x,
                                    self.webView.scrollView.contentOffset.y + r.origin.y
                                    );
            [self.webView.scrollView setContentOffset:p animated:YES];
        }
        self.jumpToFragment = nil;
    }
}

- (void)autoScrollToLastScrollOffsetIfNecessary {
    // also, need to store offsets relative to the browser view frame in case we change the layout
    if (!CGPointEqualToPoint(self.lastScrollOffset, CGPointZero) && !self.jumpToFragment) {
        [self.webView.scrollView setContentOffset:self.lastScrollOffset animated:NO];
    }
}

- (void)showAlert:(id)alertText type:(AlertType)type duration:(CGFloat)duration {
    [super showAlert:alertText type:type duration:duration];
}

- (void)doStuffOnAppear {
    // Don't move this to viewDidLoad - this is because viewDidLoad may only get
    // called very occasionally as app suspend/resume probably doesn't cause
    // viewDidLoad to fire.
    [self downloadAssetsFilesIfNecessary];

    [self performHousekeepingIfNecessary];

    //[self.view randomlyColorSubviews];
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

#pragma mark Sync config/ios.json if necessary

- (void)downloadAssetsFilesIfNecessary {
    // Sync config/ios.json at most once per day.
    [[QueuesSingleton sharedInstance].assetsFetchManager.operationQueue cancelAllOperations];

    (void)[[AssetsFileFetcher alloc] initAndFetchAssetsFileOfType:WMFAssetsFileTypeConfig
                                                      withManager:[QueuesSingleton sharedInstance].assetsFetchManager
                                                           maxAge:kWMFMaxAgeDefault];
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

- (MWKSection*)currentVisibleSection {
    NSInteger indexOfFirstOnscreenSection =
        [self.webView getIndexOfTopOnScreenElementWithPrefix:@"section_heading_and_content_block_"
                                                       count:self.article.sections.count];

    if (indexOfFirstOnscreenSection > self.article.sections.count || indexOfFirstOnscreenSection < 0) {
        return [self.article.sections.entries firstObject];
    }

    return self.article.sections[indexOfFirstOnscreenSection];
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
    }];
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

        @weakify(self);
        [_bridge addListener:@"linkClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {
            @strongify(self);
            if (!self) {
                return;
            }

            NSString* href = payload[@"href"];

            if (!(self).referencesHidden) {
                [(self) referencesHide];
            }

            if ([href wmf_isInternalLink]) {
                MWKTitle* pageTitle = [self.article.site titleWithInternalLink:href];
                [(self).delegate webViewController:(self) didTapOnLinkForTitle:pageTitle];
            } else {
                // A standard external link, either explicitly http(s) or left protocol-relative on web meaning http(s)
                if ([href hasPrefix:@"#"]) {
                    self.jumpToFragment = [href substringFromIndex:1];
                    [self jumpToFragmentIfNecessary];
                } else if ([href hasPrefix:@"//"]) {
                    // Expand protocol-relative link to https -- secure by default!
                    href = [@"https:" stringByAppendingString:href];
                }
                NSURL* url = [NSURL URLWithString:href];
                NSCAssert(url, @"Failed to from URL from link %@", href);
                if (url) {
                    [self wmf_openExternalUrl:url];
                }
            }
        }];

        [_bridge addListener:@"nonAnchorTouchEndedWithoutDragging" withBlock:^(NSString* messageType, NSDictionary* payload) {
            @strongify(self);
            if (!self) {
                return;
            }

            // Tiny delay prevents menus from occasionally appearing when user swipes to reveal toc.
            [self performSelector:@selector(animateTopAndBottomMenuReveal) withObject:nil afterDelay:0.05];

            [self referencesHide];
        }];

        [_bridge addListener:@"referenceClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {
            @strongify(self);
            if (!self) {
                return;
            }
            //NSLog(@"referenceClicked: %@", payload);
            [self referencesShow:payload];
        }];
        
        [_bridge addListener:@"editClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {
            @strongify(self);
            if (!self) {
                return;
            }
            
            NSUInteger sectionIndex = (NSUInteger)[payload[@"sectionId"] integerValue];
            if(sectionIndex < [self.article.sections count]){
                [self.delegate webViewController:self didTapEditForSection:self.article.sections[sectionIndex]];
            }
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
                                                              action:@selector(shareMenuItemTapped:)];
        [UIMenuController sharedMenuController].menuItems = @[shareSnippet];

        [_bridge addListener:@"imageClicked" withBlock:^(NSString* type, NSDictionary* payload) {
            @strongify(self);
            if (!self) {
                return;
            }

            NSString* selectedImageURL = payload[@"url"];
            NSCParameterAssert(selectedImageURL.length);
            MWKImage* selectedImage = [self.article.images largestImageVariantForURL:selectedImageURL
                                                                             cachedOnly:NO];
            NSCParameterAssert(selectedImage);
            [self presentGalleryForArticle:self.article showingImage:selectedImage];
        }];
    }
    return _bridge;
}

- (void)saveWebViewScrollOffset {
    // Don't record scroll position of "main" pages.
    if (self.article.isMain) {
        return;
    }
    if(!self.article){
        return;
    }

    [self.session.userDataStore.historyList setPageScrollPosition:self.webView.scrollView.contentOffset.y onPageInHistoryWithTitle:self.article.title];
    [self.session.userDataStore.historyList save];
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

    [self.sectionHeadersViewController updateTopHeaderForScrollOffsetY:scrollView.contentOffset.y];

    if (self.keyboardIsVisible && fabsDistanceScrolled > HIDE_KEYBOARD_ON_SCROLL_THRESHOLD) {
        [self wmf_hideKeyboard];
        //NSLog(@"Keyboard Hidden!");
    }

    [self adjustTopAndBottomMenuVisibilityOnScroll];
    [super scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
    self.scrollViewDragBeganVerticalOffset = scrollView.contentOffset.y;
}

- (void)scrollViewDidScrollToTop:(UIScrollView*)scrollView {
    [self saveWebViewScrollOffset];
    self.scrollingToTop = NO;
}

#pragma mark Menus auto show-hide on scroll / reveal on tap

- (void)adjustTopAndBottomMenuVisibilityOnScroll {
    // This method causes the menus to hide when user scrolls down and show when they scroll up.
    if (self.webView.scrollView.isDragging) {
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
        } completion:^(BOOL done){
            self.isAnimatingTopAndBottomMenuHidden = NO;
        }];
    }];
}

- (void)animateTopAndBottomMenuReveal {
    [self animateTopAndBottomMenuHidden:NO];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView*)scrollView {
    self.scrollingToTop = YES;
    [self referencesHide];

    // Called when the title bar is tapped.
    [self animateTopAndBottomMenuReveal];
    return YES;
}

#pragma mark - Scroll To

- (void)scrollToSection:(MWKSection*)section {
    [self scrollToFragment:section.anchor];
}

- (void)scrollToFragment:(NSString*)fragment {
    if (fragment.length == 0) {
        // No section so scroll to top. (Used when "Introduction" is selected.)
        [self.webView.scrollView scrollRectToVisible:CGRectMake(0, 1, 1, 1) animated:NO];
    } else{
        self.jumpToFragment = fragment;
        [self jumpToFragmentIfNecessary];
    }
}

#pragma mark Display article from data store

- (void)setArticle:(MWKArticle*)article discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod{
    _article = article;
    
#warning HAX: force the view to load
    [self view];
    
#warning TODO: remove dependency on session current article
    self.session.currentArticle = article;
    self.currentArticleDiscoveryMethod = discoveryMethod;
    
    if (![article isCached]) {
        [self showProgressViewAnimated:NO];
        return;
    }
    
    MWLanguageInfo* languageInfo = [MWLanguageInfo languageInfoForCode:self.article.title.site.language];
    NSString* uidir              = ([WikipediaAppUtils isDeviceLanguageRTL] ? @"rtl" : @"ltr");
    
    NSMutableArray* sectionTextArray = [[NSMutableArray alloc] init];
    
    for (MWKSection* section in _article.sections) {
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
    
    if (self.currentArticleDiscoveryMethod == MWKHistoryDiscoveryMethodSaved ||
        self.currentArticleDiscoveryMethod == MWKHistoryDiscoveryMethodBackForward ||
        self.currentArticleDiscoveryMethod == MWKHistoryDiscoveryMethodReloadFromNetwork ||
        self.currentArticleDiscoveryMethod == MWKHistoryDiscoveryMethodReloadFromCache) {
        MWKHistoryEntry* historyEntry = [self.session.userDataStore.historyList entryForListIndex:article.title];
        CGPoint scrollOffset          = CGPointMake(0, historyEntry.scrollPosition);
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
    
    if (!self.article.editable) {
        [self.bridge sendMessage:@"setPageProtected" withPayload:@{}];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateProgress:0.85 animated:YES completion:NULL];
    });
}

- (BOOL)isCurrentArticleSaved {
    return [self.session.userDataStore.savedPageList isSaved:self.article.title];
}

#pragma mark Scroll to last section after rotate

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [[self.webView wmf_javascriptContext][@"setPreRotationRelativeScrollOffset"] callWithArguments:nil];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self scrollToElementOnScreenBeforeRotate];
}

- (void)scrollToElementOnScreenBeforeRotate {
    // FIXME: rotating portrait/landscape repeatedly causes the webview to scroll down instead of maintaining the same position
    return;
    double finalScrollOffset = [[[self.webView wmf_javascriptContext][@"getPostRotationScrollOffset"] callWithArguments:nil] toDouble];

    [self tocScrollWebViewToPoint:CGPointMake(0, finalScrollOffset)
                         duration:0
                      thenHideTOC:NO];
}

#pragma mark Bottom menu bar

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

    self.referencesVC.delegate = self;
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

- (void)referenceViewController:(ReferencesVC*)referenceViewController didShowReferenceWithLinkID:(NSString*)linkID{
    NSString* eval = [NSString stringWithFormat:@"\
                      document.getElementById('%@').oldBackgroundColor = document.getElementById('%@').style.backgroundColor;\
                      document.getElementById('%@').style.backgroundColor = '#999';\
                      document.getElementById('%@').style.borderRadius = 2;\
                      ", linkID, linkID, linkID, linkID];
    [self.webView stringByEvaluatingJavaScriptFromString:eval];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didFinishShowingReferenceWithLinkID:(NSString*)linkID{
    NSString* eval = [NSString stringWithFormat:@"\
                      document.getElementById('%@').style.backgroundColor = document.getElementById('%@').oldBackgroundColor;\
                      ", linkID, linkID];
    [self.webView stringByEvaluatingJavaScriptFromString:eval];
}


- (void)referenceViewControllerCloseReferences:(ReferencesVC*)referenceViewController{
    [self referencesHide];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectInternalReferenceWithFragment:(NSString*)fragment{
    [self scrollToFragment:fragment];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectReferenceWithTitle:(MWKTitle*)title{
    [self.delegate webViewController:self didTapOnLinkForTitle:title];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectExternalReferenceWithURL:(NSURL*)url{
    [self wmf_openExternalUrl:url];
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
    } completion:nil];
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

#pragma mark - Share Actions

- (void)shareMenuItemTapped:(id)sender {
    [self shareSnippet:self.selectedText];
}

#pragma mark - Sharing

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(shareSnippet:)) {
        if ([self.selectedText isEqualToString:@""]) {
            return NO;
        }
        [self.delegate webViewController:self didSelectText:self.selectedText];
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

- (NSString*)selectedText {
    NSString* selectedText =
        [[self.webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"] wmf_shareSnippetFromText];
    return selectedText.length < kMinimumTextSelectionLength ? @"" : selectedText;
}

- (void)shareSnippet:(NSString*)snippet {
    [self.webView wmf_suppressSelection];
    [self.delegate webViewController:self didTapShareWithSelectedText:snippet];
}

- (void)editHistoryButtonPushed {
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:[PageHistoryViewController wmf_initialViewControllerFromClassStoryboard]];
    [self presentViewController:nc animated:YES completion:nil];
}

@end
