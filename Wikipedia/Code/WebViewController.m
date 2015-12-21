//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewController_Private.h"

#import "Wikipedia-Swift.h"

@import Masonry;
@import BlocksKit.BlocksKit_UIKit;

#import "NSString+WMFHTMLParsing.h"

#import "MWKArticle.h"
#import "MWKSection.h"
#import "MWKSectionList.h"
#import "MWKSite.h"
#import "MWKImageList.h"
#import "MWKTitle.h"

#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIViewController+WMFStoryboardUtilities.h"

#import "WMFShareCardViewController.h"
#import "UIWebView+WMFSuppressSelection.h"
#import "UIView+WMFRTLMirroring.h"
#import "PageHistoryViewController.h"

#import "WMFSectionHeadersViewController.h"
#import "WMFSectionHeaderEditProtocol.h"

#import "UIWebView+WMFJavascriptContext.h"
#import "UIWebView+WMFTrackingView.h"
#import "UIWebView+ElementLocation.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "NSURL+Extras.h"

typedef NS_ENUM (NSInteger, WMFWebViewAlertType) {
    WMFWebViewAlertZeroWebPage,
    WMFWebViewAlertZeroCharged,
    WMFWebViewAlertZeroInterstitial
};

NSString* const WMFLicenseTitleOnENWiki =
    @"Wikipedia:Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License";

@interface WebViewController () <ReferencesVCDelegate>

@property (nonatomic, strong) UIBarButtonItem* buttonEditHistory;

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
@property (nonatomic, strong) MASConstraint* headerHeight;
@property (nonatomic, strong) UIView* footerContainerView;
@property (nonatomic, strong) NSMutableDictionary* footerViewHeadersByIndex;
@property (nonatomic, strong) WMFArticleFooterView* footerLicenseView;

@property (nonatomic, strong) WMFSectionHeadersViewController* sectionHeadersViewController;

/**
 *  Calculates the amount needed to compensate to specific HTML element locations.
 *
 *  Used when scrolling to fragments instead of setting @c location.hash since setting the offset manually allows us to
 *  animate the navigation.  However, we can't use the values provided by the webview as-is, since we've added a header
 *  view on top of the browser view.  This has the effect of offsetting the bounding rects of HTML elements by the amount
 *  of the header view which is currently on screen.  As a result, we calculate the amount of the header view that is showing,
 *  and return it from this method in order to get the <i>actual</i> bounding rect, compensated for our header view if
 *  necessary.
 *
 *  @return The vertical offset to apply to client bounding rects received from the web view.
 */
- (CGFloat)clientBoundingRectVerticalOffset;

@end

@implementation WebViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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

#pragma mark - Tool Bar

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

    self.isPeeking = NO;
    [self addHeaderView];
    [self addFooterView];

    self.referencesHidden = YES;

    [self.navigationController.navigationBar wmf_mirrorIfDeviceRTL];
    [self.navigationController.toolbar wmf_mirrorIfDeviceRTL];

    [self setupBottomMenuButtons];

    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    self.webView.scrollView.backgroundColor  = [UIColor wmf_articleBackgroundColor];

    self.zeroStatusLabel.font = [UIFont systemFontOfSize:ALERT_FONT_SIZE];
    self.zeroStatusLabel.text = @"";

    self.webView.backgroundColor = [UIColor whiteColor];

    self.view.backgroundColor = CHROME_COLOR;

    [self observeWebScrollViewContentSize];

    [self displayArticle];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self layoutWebViewSubviews];
    [self.webView.scrollView wmf_shouldScrollToTopOnStatusBarTap:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutWebViewSubviews];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)willTransitionToTraitCollection:(UITraitCollection*)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > _Nonnull context) {
        [self layoutWebViewSubviews];
    } completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [[self.webView wmf_javascriptContext][@"setPreRotationRelativeScrollOffset"] callWithArguments:nil];
    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > _Nonnull context) {
        [self scrollToElementOnScreenBeforeRotate];
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

#pragma mark - Headers & Footers

- (void)scrollToFooterAtIndex:(NSUInteger)index {
    UIView* footerView       = self.footerViewControllers[index].view;
    UIView* footerViewHeader = self.footerViewHeadersByIndex[@(index)];
    UIView* viewToScrollTo   = footerViewHeader ? : footerView;

    CGPoint footerViewOrigin = [self.webView.scrollView convertPoint:viewToScrollTo.frame.origin
                                                            fromView:self.footerContainerView];
    footerViewOrigin.y -= self.webView.scrollView.contentInset.top;
    [self.webView.scrollView setContentOffset:footerViewOrigin animated:YES];
}

- (NSInteger)visibleFooterIndex {
    CGRect const scrollViewContentFrame = self.webView.scrollView.wmf_contentFrame;
    if (!CGRectIntersectsRect(scrollViewContentFrame, self.footerContainerView.frame)) {
        return NSNotFound;
    }
    return
        [self.footerContainerView.subviews indexOfObjectPassingTest:^BOOL (__kindof UIView* _Nonnull footerView,
                                                                           NSUInteger idx,
                                                                           BOOL* _Nonnull stop) {
        CGRect absoluteFooterViewFrame = [self.webView.scrollView convertRect:footerView.frame
                                                                     fromView:self.footerContainerView];
        if (CGRectIntersectsRect(scrollViewContentFrame, absoluteFooterViewFrame)) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
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

- (UIView*)footerContainerView {
    if (!_footerContainerView) {
        _footerContainerView                 = [UIView new];
        _footerContainerView.backgroundColor = [UIColor wmf_articleBackgroundColor];
    }
    return _footerContainerView;
}

- (WMFArticleFooterView*)footerLicenseView {
    if (!_footerLicenseView) {
        _footerLicenseView = [WMFArticleFooterView wmf_viewFromClassNib];
        @weakify(self);
        [_footerLicenseView.showLicenseButton bk_addEventHandler:^(id sender) {
            @strongify(self);
            MWKSite* site = [[MWKSite alloc] initWithDomain:WMFDefaultSiteDomain language:@"en"];
            [self.delegate webViewController:self didTapOnLinkForTitle:[site titleWithString:WMFLicenseTitleOnENWiki]];
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _footerLicenseView;
}

- (void)addFooterView {
    self.footerViewHeadersByIndex = [NSMutableDictionary dictionary];
    [self addFooterContainerView];
    [self addFooterContentViews];
}

- (void)addFooterContainerView {
    [self.webView.scrollView addSubview:self.footerContainerView];
    [self.footerContainerView mas_remakeConstraints:^(MASConstraintMaker* make) {
        // lead/trail must be constained to webview, the scrollview doesn't define a width
        make.leading.and.trailing.equalTo(self.webView);
        make.top.equalTo([[self.webView wmf_browserView] mas_bottom]);
        make.bottom.equalTo(self.webView.scrollView);
    }];
}

- (void)addFooterContentViews {
    NSParameterAssert(self.isViewLoaded);
    MASViewAttribute* lastAnchor = [self.footerViewControllers bk_reduce:self.footerContainerView.mas_top
                                                               withBlock:^MASViewAttribute*(MASViewAttribute* topAnchor,
                                                                                            UIViewController* childVC) {
        NSString* footerTitle = [self.delegate webViewController:self titleForFooterViewController:childVC];
        if (footerTitle) {
            WMFArticleFooterViewHeader* header = [WMFArticleFooterViewHeader wmf_viewFromClassNib];
            self.footerViewHeadersByIndex[@([self.footerViewControllers indexOfObject:childVC])] = header;
            header.headerLabel.text = footerTitle;
            [self.footerContainerView addSubview:header];
            [header mas_remakeConstraints:^(MASConstraintMaker* make) {
                make.leading.and.trailing.equalTo(self.footerContainerView);
                make.top.equalTo(topAnchor);
            }];
            topAnchor = header.mas_bottom;
        }

        [self.footerContainerView addSubview:childVC.view];
        [childVC.view mas_remakeConstraints:^(MASConstraintMaker* make) {
            make.leading.and.trailing.equalTo(self.footerContainerView);
            make.top.equalTo(topAnchor);
        }];
        [childVC didMoveToParentViewController:self];
        return childVC.view.mas_bottom;
    }];

    if (!lastAnchor) {
        lastAnchor = self.footerContainerView.mas_top;
    }

    [self.footerContainerView addSubview:self.footerLicenseView];
    [self.footerLicenseView mas_remakeConstraints:^(MASConstraintMaker* make) {
        make.top.equalTo(lastAnchor);
        make.leading.and.trailing.equalTo(self.footerContainerView);
        make.bottom.equalTo(self.footerContainerView);
    }];
}

- (void)setFooterViewControllers:(NSArray<UIViewController*>*)footerViewControllers {
    [_footerViewControllers bk_each:^(UIViewController* childVC) {
        [childVC willMoveToParentViewController:nil];
        [childVC.view removeFromSuperview];
        [childVC removeFromParentViewController];
    }];
    _footerViewControllers = [footerViewControllers copy];
    [_footerViewControllers bk_each:^(UIViewController* childVC) {
        [self addChildViewController:childVC];
        // didMoveToParent is called when they are added to the view
    }];
    [self addFooterView];
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

    if (floor(browserView.frame.origin.y) != floor(headerBottom)) { // Prevent weird recursion when doing 3d touch peek.
        [browserView setFrame:(CGRect){
             .origin = CGPointMake(0, headerBottom),
             .size = browserView.frame.size
         }];
    }

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
    if (self.article.isMain || !self.article.imageURL) {
        return 0;
    }
    switch (traitCollection.verticalSizeClass) {
        case UIUserInterfaceSizeClassRegular:
            return 210;
        default:
            return 0;
    }
}

#pragma mark - Scrolling

- (CGFloat)clientBoundingRectVerticalOffset {
    NSParameterAssert(self.isViewLoaded);
    CGRect headerIntersection =
        CGRectIntersection(self.webView.scrollView.wmf_contentFrame, self.headerViewController.view.frame);
    return headerIntersection.size.height;
}

- (void)scrollToFragment:(NSString*)fragment {
    [self scrollToFragment:fragment animated:YES];
}

- (void)scrollToFragment:(NSString*)fragment animated:(BOOL)animated {
    if (fragment.length == 0) {
        // No section so scroll to top. (Used when "Introduction" is selected.)
        [self.webView.scrollView scrollRectToVisible:CGRectMake(0, 1, 1, 1) animated:animated];
    } else {
        if (!animated) {
            [self.webView.wmf_javascriptContext.globalObject invokeMethod:@"scrollToFragment"
                                                            withArguments:@[fragment]];
            return;
        }
        CGRect r = [self.webView getScreenRectForHtmlElementWithId:fragment];
        if (!CGRectIsNull(r)) {
            CGPoint elementOrigin =
                CGPointMake(self.webView.scrollView.contentOffset.x,
                            self.webView.scrollView.contentOffset.y + r.origin.y + [self clientBoundingRectVerticalOffset]);
            [self.webView.scrollView wmf_safeSetContentOffset:elementOrigin animated:YES];
        }
    }
}

- (void)scrollToSection:(MWKSection*)section animated:(BOOL)animated {
    [self scrollToFragment:section.anchor animated:animated];
}

- (nullable MWKSection*)currentVisibleSection {
    NSInteger indexOfFirstOnscreenSection =
        [self.webView getIndexOfTopOnScreenElementWithPrefix:@"section_heading_and_content_block_"
                                                       count:self.article.sections.count];
    return indexOfFirstOnscreenSection == NSNotFound ? nil : self.article.sections[indexOfFirstOnscreenSection];
}

- (void)scrollToVerticalOffset:(CGFloat)offset {
    [self.webView.scrollView wmf_safeSetContentOffset:CGPointMake(0, offset) animated:NO];
}

- (CGFloat)currentVerticalOffset {
    return self.webView.scrollView.contentOffset.y;
}

- (BOOL)isWebContentVisible {
    return CGRectIntersectsRect(self.webView.scrollView.wmf_contentFrame, self.webView.wmf_browserView.frame);
}

- (BOOL)rectIntersectsWebViewTop:(CGRect)rect {
    CGFloat elementScreenYOffset =
        rect.origin.y - self.webView.scrollView.contentOffset.y + rect.size.height;
    return (elementScreenYOffset > 0) && (elementScreenYOffset < rect.size.height);
}

- (void)tocScrollWebViewToPoint:(CGPoint)point
                       duration:(CGFloat)duration
                    thenHideTOC:(BOOL)hideTOC {
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        [self.webView.scrollView wmf_safeSetContentOffset:point animated:NO];
    } completion:^(BOOL done) {
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
        [_bridge addListener:@"DOMContentLoaded" withBlock:^(NSString* type, NSDictionary* payload) {
            @strongify(self);
            //Need to introduce a delay here or the webview still might not be loaded. Should look at using the webview callbacks instead.
            dispatchOnMainQueueAfterDelayInSeconds(0.1, ^{
                [self.delegate webViewController:self didLoadArticle:self.article];
                [self.sectionHeadersViewController resetHeaders];
            });
        }];

        [_bridge addListener:@"linkClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {
            @strongify(self);
            if (!self) {
                return;
            }

            if (self.isPeeking) {
                self.isPeeking = NO;
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
                    [self scrollToFragment:[href substringFromIndex:1]];
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
            if (sectionIndex < [self.article.sections count]) {
                [self.delegate webViewController:self didTapEditForSection:self.article.sections[sectionIndex]];
            }
        }];

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
            if (!selectedImageURL.length) {
                DDLogError(@"Image clicked callback invoked with empty URL: %@", payload);
                return;
            }

            [self.delegate webViewController:self didTapImageWithSourceURLString:selectedImageURL];
        }];
    }
    return _bridge;
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

#pragma mark - Display article

- (void)setArticle:(MWKArticle*)article {
    _article = article;

    WMF_TECH_DEBT_TODO(remove dependency on session current article)
    self.session.currentArticle = article;

    if ([self isViewLoaded]) {
        [self displayArticle];
    }
}

- (void)displayArticle {
    if (!self.article) {
        return;
    }

    NSString* html = [self.article articleHTML];

    MWLanguageInfo* languageInfo = [MWLanguageInfo languageInfoForCode:self.article.site.language];
    NSString* uidir              = ([WikipediaAppUtils isDeviceLanguageRTL] ? @"rtl" : @"ltr");

    // If any of these are nil, the bridge "sendMessage:" calls will crash! So catch 'em here.
    BOOL safeToCrossBridge = (languageInfo.code && languageInfo.dir && uidir && html);
    if (!safeToCrossBridge) {
        NSLog(@"\n\nUnsafe to cross JS bridge!");
        NSLog(@"\tlanguageInfo.code = %@", languageInfo.code);
        NSLog(@"\tlanguageInfo.dir = %@", languageInfo.dir);
        NSLog(@"\tuidir = %@", uidir);
        NSLog(@"\thtmlStr is nil = %d\n\n", (html == nil));
        //TODO: output "could not load page" alert and/or show last page?
        return;
    }

    [self.bridge loadHTML:html withAssetsFile:@"index.html"];

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

    [self.footerLicenseView setLicenseTextForSite:self.article.site];
}

#pragma mark Scroll to last section after rotate

- (void)scrollToElementOnScreenBeforeRotate {
    double finalScrollOffset =
        [[[self.webView wmf_javascriptContext][@"getPostRotationScrollOffset"] callWithArguments:nil] toDouble]
        + [self clientBoundingRectVerticalOffset];
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

- (void)referenceViewController:(ReferencesVC*)referenceViewController didShowReferenceWithLinkID:(NSString*)linkID {
    NSString* eval = [NSString stringWithFormat:@"\
                      document.getElementById('%@').oldBackgroundColor = document.getElementById('%@').style.backgroundColor;\
                      document.getElementById('%@').style.backgroundColor = '#999';\
                      document.getElementById('%@').style.borderRadius = 2;\
                      ", linkID, linkID, linkID, linkID];
    [self.webView stringByEvaluatingJavaScriptFromString:eval];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didFinishShowingReferenceWithLinkID:(NSString*)linkID {
    NSString* eval = [NSString stringWithFormat:@"\
                      document.getElementById('%@').style.backgroundColor = document.getElementById('%@').oldBackgroundColor;\
                      ", linkID, linkID];
    [self.webView stringByEvaluatingJavaScriptFromString:eval];
}

- (void)referenceViewControllerCloseReferences:(ReferencesVC*)referenceViewController {
    [self referencesHide];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectInternalReferenceWithFragment:(NSString*)fragment {
    [self scrollToFragment:fragment];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectReferenceWithTitle:(MWKTitle*)title {
    [self.delegate webViewController:self didTapOnLinkForTitle:title];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectExternalReferenceWithURL:(NSURL*)url {
    [self wmf_openExternalUrl:url];
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

#pragma mark - Previewing

- (JSValue*)htmlElementAtLocation:(CGPoint)location {
    return [[self.webView wmf_javascriptContext][@"getElementFromPoint"] callWithArguments:@[@(location.x), @(location.y)]];
}

- (NSURL*)urlForHTMLElement:(JSValue*)element {
    if ([[[element valueForProperty:@"tagName"] toString] isEqualToString:@"A"] && [element valueForProperty:@"href"]) {
        NSString* urlString = [[element valueForProperty:@"href"] toString];
        return (!urlString) ? nil : [NSURL URLWithString:urlString];
    }
    return nil;
}

- (CGRect)rectForHTMLElement:(JSValue*)element {
    JSValue* rect  = [element invokeMethod:@"getBoundingClientRect" withArguments:@[]];
    CGFloat left   = (CGFloat)[[rect valueForProperty:@"left"] toDouble];
    CGFloat right  = (CGFloat)[[rect valueForProperty:@"right"] toDouble];
    CGFloat top    = (CGFloat)[[rect valueForProperty:@"top"] toDouble];
    CGFloat bottom = (CGFloat)[[rect valueForProperty:@"bottom"] toDouble];
    return CGRectMake(left, top + self.webView.scrollView.contentOffset.y, right - left, bottom - top);
}

@end
