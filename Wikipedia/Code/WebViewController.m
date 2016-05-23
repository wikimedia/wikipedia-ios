//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewController_Private.h"

#import "Wikipedia-Swift.h"

#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit+UIKit.h>
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
#import "PageHistoryViewController.h"

#import "UIWebView+WMFJavascriptContext.h"
#import "UIWebView+WMFTrackingView.h"
#import "UIWebView+ElementLocation.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "NSURL+WMFExtras.h"

#import "WMFZeroMessage.h"
#import <hpple/TFHpple.h>

typedef NS_ENUM (NSInteger, WMFWebViewAlertType) {
    WMFWebViewAlertZeroWebPage,
    WMFWebViewAlertZeroCharged,
    WMFWebViewAlertZeroInterstitial
};

NSString* const WMFCCBySALicenseURL =
    @"https://creativecommons.org/licenses/by-sa/3.0/";

@interface WebViewController () <ReferencesVCDelegate>

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

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.isPeeking = NO;
    [self addHeaderView];
    [self addFooterView];

    self.referencesHidden = YES;

    self.view.clipsToBounds               = NO;
    self.webView.clipsToBounds            = NO;
    self.webView.scrollView.clipsToBounds = NO;

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateZeroStateWithNotification:)
                                                 name:WMFZeroDispositionDidChange
                                               object:nil];
    // should happen in will appear to prevent bar from being incorrect during transitions
    [self updateZeroState];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutWebViewSubviews];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WMFZeroDispositionDidChange object:nil];
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

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    @try {
        JSContext* context = [self.webView wmf_javascriptContext];
        if (!context) {
            return;
        }
        [context[@"setPreRotationRelativeScrollOffset"] callWithArguments:nil];
    }@catch (NSException* exception) {
        DDLogError(@"Expection when accessing the JS context during ize transition, %@: %@", exception.name, exception.reason);
    }

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

#pragma mark - Zero

- (void)updateZeroStateWithNotification:(NSNotification*)notification {
    [self updateZeroState];
}

- (void)updateZeroState {
    if ([[SessionSingleton sharedInstance] zeroConfigState].disposition) {
        [self showZeroBannerWithMessage:[[[SessionSingleton sharedInstance] zeroConfigState] zeroMessage]];
    } else {
        self.zeroStatusLabel.text = @"";
    }
}

- (void)showZeroBannerWithMessage:(WMFZeroMessage*)zeroMessage {
    self.zeroStatusLabel.text            = zeroMessage.message;
    self.zeroStatusLabel.textColor       = zeroMessage.foreground;
    self.zeroStatusLabel.backgroundColor = zeroMessage.background;
}

#pragma mark - Headers & Footers

- (UIView*)footerAtIndex:(NSUInteger)index {
    UIView* footerView       = self.footerViewControllers[index].view;
    UIView* footerViewHeader = self.footerViewHeadersByIndex[@(index)];
    return footerViewHeader ? : footerView;
}

- (void)scrollToFooterAtIndex:(NSUInteger)index {
    UIView* viewToScrollTo   = [self footerAtIndex:index];
    CGPoint footerViewOrigin = [self.webView.scrollView convertPoint:viewToScrollTo.frame.origin
                                                            fromView:self.footerContainerView];
    footerViewOrigin.y -= self.webView.scrollView.contentInset.top;
    [self.webView.scrollView setContentOffset:footerViewOrigin animated:YES];
}

- (void)accessibilityCursorToFooterAtIndex:(NSUInteger)index {
    UIView* viewToScrollTo = [self footerAtIndex:index];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, viewToScrollTo);
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
    if (!self.headerView) {
        return;
    }
    [self.webView.scrollView addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker* make) {
        // lead/trail must be constained to webview, the scrollview doesn't define a width
        make.leading.and.trailing.equalTo(self.webView);
        make.top.equalTo(self.webView.scrollView);
        self.headerHeight = make.height.equalTo(@([self headerHeightForCurrentTraitCollection]));
    }];
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
            [self wmf_openExternalUrl:[NSURL URLWithString:WMFCCBySALicenseURL]];
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _footerLicenseView;
}

- (void)addFooterView {
    if (!self.article) {
        return;
    }
    if ([self.article.title isNonStandardTitle]) {
        return;
    }
    self.footerViewHeadersByIndex = [NSMutableDictionary dictionary];
    [self addFooterContainerView];
    [self addFooterContentViews];
    [self.footerContainerView wmf_recursivelyDisableScrollsToTop];
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
    if ([self.article.title isNonStandardTitle]) {
        return;
    }
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
    if (WMF_EQUAL(self.footerViewControllers, isEqualToArray:, footerViewControllers)) {
        return;
    }
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

- (void)setHeaderView:(UIView*)headerView {
    NSAssert(!self.headerView, @"Dynamic/re-configurable header view is not supported.");
    NSAssert(!self.isViewLoaded, @"Expected header to be configured before viewDidLoad.");
    _headerView = headerView;
}

- (void)layoutWebViewSubviews {
    [self.headerHeight setOffset:[self headerHeightForCurrentTraitCollection]];
    CGFloat headerBottom = CGRectGetMaxY(self.headerView.frame);
    /*
       HAX: need to manage positioning the browser view manually.
       using constraints seems to prevent the browser view size and scrollview contentSize from being set
       properly.
     */
    UIView* browserView = [self.webView wmf_browserView];

    if (floor(CGRectGetMinY(browserView.frame)) != floor(headerBottom)) { // Prevent weird recursion when doing 3d touch peek.
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
    if (self.article.isMain || !self.article.imageURL || [self.article.title isNonStandardTitle]) {
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
        CGRectIntersection(self.webView.scrollView.wmf_contentFrame, self.headerView.frame);
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

- (void)accessibilityCursorToSection:(MWKSection*)section {
    // This might shift the visual scroll position. To prevent it affecting other users,
    // we will only do it when we detect than an assistive technology which actually needs this is running.
    if (UIAccessibilityIsVoiceOverRunning()) {
        [self.webView.wmf_javascriptContext.globalObject invokeMethod:@"accessibilityCursorToFragment"
                                                        withArguments:@[section.anchor]];
    }
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
    if (isnan(point.x) || isnan(point.y)) {
        return;
        DDLogError(@"Attempted to scroll ToC to Nan value, ignoring");
    }
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

        UIMenuItem* shareSnippet = [[UIMenuItem alloc] initWithTitle:MWLocalizedString(@"share-a-fact-share-menu-item", nil)
                                                              action:@selector(shareMenuItemTapped:)];
        [UIMenuController sharedMenuController].menuItems = @[shareSnippet];

        [_bridge addListener:@"imageClicked" withBlock:^(NSString* type, NSDictionary* payload) {
            @strongify(self);
            if (!self) {
                return;
            }

            NSNumber* imageWidth = payload[@"width"];
            NSNumber* imageHeight = payload[@"height"];
            CGSize imageSize = CGSizeMake(imageWidth.floatValue, imageHeight.floatValue);
            if (![MWKImage isSizeLargeEnoughForGalleryInclusion:imageSize]) {
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
    NSString* uidir              = ([[UIApplication sharedApplication] wmf_isRTL] ? @"rtl" : @"ltr");

    [self.bridge loadHTML:html withAssetsFile:@"index.html"];

    // NSLog(@"languageInfo = %@", languageInfo.code);

    // If any of these are nil, the bridge "sendMessage:" calls will crash! So catch 'em here.
    BOOL safeToCrossBridge = (languageInfo.code && languageInfo.dir && uidir && html);
    if (safeToCrossBridge) {
        [self.bridge sendMessage:@"setLanguage"
                     withPayload:@{
             @"lang": languageInfo.code,
             @"dir": languageInfo.dir,
             @"uidir": uidir
         }];
    }

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
    WMF_TECH_DEBT_WARN(use size classes instead of interfaceOrientation)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGFloat percentOfHeight = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.4 : 0.6;
#pragma clang diagnostic pop
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

- (void)setFontSizeMultiplier:(NSNumber*)fontSize {
    if (fontSize == nil) {
        fontSize = @(100);
    }
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.querySelector('body').style['-webkit-text-size-adjust'] = '%ld%%';", fontSize.integerValue]];
    [[NSUserDefaults standardUserDefaults] wmf_setReadingFontSize:fontSize];
    [[NSUserDefaults standardUserDefaults] synchronize];
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




















-(void)didReceiveMemoryWarning {


    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    

    
    
    
//EXAMPLE ONE: "On this day" matching results seen here: https://en.m.wikipedia.org/wiki/Wikipedia:On_this_day/Today
    //Note: change the "May+20" in the url below for different date results.
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://en.wikipedia.org/w/api.php?action=query&titles=Wikipedia:Selected%20anniversaries/May+20&prop=revisions&rvprop=content&rvparse=1&format=json"]];
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {

            NSString* responseHtml = [[[responseObject[@"query"][@"pages"] allValues] firstObject][@"revisions"] firstObject][@"*"];
            NSArray* results = [self serializeResponseHTML:responseHtml withXPATH:@"//li"];
            NSLog(@"\n\nON THIS DAY =\n%@\n\n", [results wmf_safeSubarrayWithRange:NSMakeRange(results.count - 5, 5)]);

        }
    }];
    [dataTask resume];
    
    
    
    
//EXAMPLE TWO: "Events, births and deaths" matching results seen here: https://en.m.wikipedia.org/wiki/May_20
    //Note: change the "May+20" in the url below for different date results.
    
    NSURLRequest *request2 = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://en.wikipedia.org/w/api.php?action=query&format=json&prop=revisions&titles=May+20&rvprop=content&rvparse=1&format=json"]];
    NSURLSessionDataTask *dataTask2 = [manager dataTaskWithRequest:request2 completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            
            NSString* responseHtml = [[[responseObject[@"query"][@"pages"] allValues] firstObject][@"revisions"] firstObject][@"*"];
            NSString* xpath = @"//span[@id='%@']/following::ul[1]/li";
            NSArray* events = [self serializeResponseHTML:responseHtml withXPATH:[NSString stringWithFormat:xpath, @"Events"]];
            NSArray* births = [self serializeResponseHTML:responseHtml withXPATH:[NSString stringWithFormat:xpath, @"Births"]];
            NSArray* deaths = [self serializeResponseHTML:responseHtml withXPATH:[NSString stringWithFormat:xpath, @"Deaths"]];
            NSArray* holidays = [self serializeHolidaysResponseHTML:responseHtml withXPATH:[NSString stringWithFormat:xpath, @"Holidays_and_observances"]];
            
            NSDictionary* results = @{
                                      @"events": events,
                                      @"births": births,
                                      @"deaths": deaths,
                                      @"holidays": holidays
                                      };
            NSLog(@"\n\nFULL DAY RESULTS (events, births, deaths and holidays) =\n%@\n\n", results);
            
        }
    }];
    [dataTask2 resume];
}











- (NSArray*)serializeResponseHTML:(NSString*)html withXPATH:(NSString*)xpath {
    NSArray* listItems = [[[TFHpple hppleWithHTMLData:[html dataUsingEncoding:NSUTF8StringEncoding]] searchWithXPathQuery:xpath] valueForKey:WMF_SAFE_KEYPATH(TFHppleElement.new, raw)];
    
    NSArray* cleanedResults = [[[listItems bk_map:^ id (NSString* listItem) {
        return @{
                 @"text": [listItem wmf_stringByRemovingHTML],
                 @"html": listItem
                 };
    }] bk_select:^ BOOL (NSDictionary* listItemInfo) {
        // Keep only if text starts with year followed by a dash and a space " 1974 - "
        NSRange range = [listItemInfo[@"text"] rangeOfString:@"^\\s*\\d+\\s*–\\s" options:NSRegularExpressionSearch];
        return range.location != NSNotFound;
    }] bk_map:^ id (NSDictionary* listItemInfo) {
        NSString* itemHtml = listItemInfo[@"html"];
        NSArray* wikiLinks = [itemHtml componentsSeparatedByString:@" href=\"/wiki/"];
        __block NSString* mainLink = nil;
        if (wikiLinks.count > 1) {
            // Hrefs found, remove first item which is cruft from componentsSeparatedByString.
            wikiLinks = [wikiLinks subarrayWithRange:NSMakeRange(1, wikiLinks.count - 1)];
            wikiLinks = [[wikiLinks bk_map:^id (NSString* stringStartingWithHrefValue) {
                NSRange range = [stringStartingWithHrefValue rangeOfString:@"\""];
                NSString* page = (range.location != NSNotFound) ? [stringStartingWithHrefValue wmf_safeSubstringToIndex:range.location] : stringStartingWithHrefValue;

                NSString* wikiLink = [@"/wiki/" stringByAppendingString:page];
                
                NSRange boldRange = [stringStartingWithHrefValue rangeOfString:@"</a>\\s*</b>" options:NSRegularExpressionSearch];
                if(boldRange.location != NSNotFound){
                    mainLink = wikiLink;
                }

                return wikiLink;
            }] bk_select:^ BOOL (NSString* wikiLink) {
                NSRange range = [wikiLink rangeOfString:@"^/wiki/\\d+$" options:NSRegularExpressionSearch];
                BOOL isYearLink = range.location != NSNotFound;
                return !isYearLink && ![wikiLink isEqualToString:mainLink];
            }];
        }
        
        NSString* text = listItemInfo[@"text"];
        NSRange rangeOfDashSpace = [text rangeOfString:@"– "];
        NSInteger year = [[text wmf_safeSubstringToIndex:rangeOfDashSpace.location] integerValue];
        NSString* textAfterYear = [text wmf_safeSubstringFromIndex:rangeOfDashSpace.location + rangeOfDashSpace.length];
        
        // If we haven't already determined a mainLink, use the first of the other links.
        if (!mainLink && wikiLinks.count > 0) {
            mainLink = wikiLinks.firstObject;
            if (wikiLinks.count == 1) {
                wikiLinks = @[];
            }else{
                wikiLinks = [wikiLinks wmf_safeSubarrayWithRange:NSMakeRange(1, wikiLinks.count -1)];
            }
        }
        
        return @{
                 @"year": @(year),
                 @"year_page": [NSString stringWithFormat:@"/wiki/%ld", (long)year],
                 @"text": textAfterYear,
                 @"page": mainLink,
                 @"other_pages": wikiLinks ? wikiLinks : @[],
                 };
    }];
    return cleanedResults;
}



















- (NSArray*)serializeHolidaysResponseHTML:(NSString*)html withXPATH:(NSString*)xpath {
    NSArray* listItems = [[[TFHpple hppleWithHTMLData:[html dataUsingEncoding:NSUTF8StringEncoding]] searchWithXPathQuery:xpath] valueForKey:WMF_SAFE_KEYPATH(TFHppleElement.new, raw)];
    
    NSArray* cleanedResults = [[listItems bk_map:^ id (NSString* listItem) {
        NSString* text = [listItem wmf_stringByRemovingHTML];
        text = text ? [text wmf_trim] : @"";
        return @{
                 @"text": text,
                 @"html": listItem
                 };
    }] bk_map:^ id (NSDictionary* listItemInfo) {
        NSString* itemHtml = listItemInfo[@"html"];
        NSArray* wikiLinks = [itemHtml componentsSeparatedByString:@" href=\"/wiki/"];
        __block NSString* mainLink = nil;
        if (wikiLinks.count > 1) {
            // Hrefs found, remove first item which is cruft from componentsSeparatedByString.
            wikiLinks = [wikiLinks subarrayWithRange:NSMakeRange(1, wikiLinks.count - 1)];
            wikiLinks = [[wikiLinks bk_map:^id (NSString* stringStartingWithHrefValue) {
                NSRange range = [stringStartingWithHrefValue rangeOfString:@"\""];
                NSString* page = (range.location != NSNotFound) ? [stringStartingWithHrefValue wmf_safeSubstringToIndex:range.location] : stringStartingWithHrefValue;
                
                NSString* wikiLink = [@"/wiki/" stringByAppendingString:page];
                
                NSRange boldRange = [stringStartingWithHrefValue rangeOfString:@"</a>\\s*</b>" options:NSRegularExpressionSearch];
                if(boldRange.location != NSNotFound){
                    mainLink = wikiLink;
                }
                
                return wikiLink;
            }] bk_select:^ BOOL (NSString* wikiLink) {
                NSRange range = [wikiLink rangeOfString:@"^/wiki/\\d+$" options:NSRegularExpressionSearch];
                BOOL isYearLink = range.location != NSNotFound;
                return !isYearLink && ![wikiLink isEqualToString:mainLink];
            }];
        }
        
        // If we haven't already determined a mainLink, use the first of the other links.
        if (!mainLink && wikiLinks.count > 0) {
            mainLink = wikiLinks.firstObject;
            if (wikiLinks.count == 1) {
                wikiLinks = @[];
            }else{
                wikiLinks = [wikiLinks wmf_safeSubarrayWithRange:NSMakeRange(1, wikiLinks.count -1)];
            }
        }
        
        return @{
                 @"text": listItemInfo[@"text"] ? listItemInfo[@"text"] : @"",
                 @"page": mainLink,
                 @"other_pages": wikiLinks ? wikiLinks : @[],
                 };
    }];
    return cleanedResults;
}














@end




@interface WMFWebView : UIWebView

@end


@implementation WMFWebView

//Disable OS share menu when selecting text
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == NSSelectorFromString(@"_share:")) {
        return NO;
    }
    return [super canPerformAction:action withSender:sender];
}

@end

