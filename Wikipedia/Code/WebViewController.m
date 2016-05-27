//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewController_Private.h"

#import "Wikipedia-Swift.h"

@import WebKit;
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
#import "WKWebView+WMFSuppressSelection.h"
#import "PageHistoryViewController.h"

#import "WKWebView+WMFTrackingView.h"
#import "WKWebView+ElementLocation.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "NSURL+WMFExtras.h"

#import "WMFZeroMessage.h"
#import "WKWebView+LoadAssetsHtml.h"

typedef NS_ENUM (NSInteger, WMFWebViewAlertType) {
    WMFWebViewAlertZeroWebPage,
    WMFWebViewAlertZeroCharged,
    WMFWebViewAlertZeroInterstitial
};

NSString* const WMFCCBySALicenseURL =
    @"https://creativecommons.org/licenses/by-sa/3.0/";

@interface WebViewController () <ReferencesVCDelegate, WKScriptMessageHandler>

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
@property (nonatomic, strong) IBOutlet UIView* containerView;

@end

@implementation WebViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self unobserveTopAndBottomNativeViewFrames];
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

#pragma mark - WebView Javascript configuration

- (NSString*)apostropheEscapedArticleLanguageLocalizedStringForKey:(NSString*)key {
    return [MWSiteLocalizedString(self.article.site, key, nil) stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
}

- (NSString*)tableTransformJS {
    return
        [NSString stringWithFormat:@"window.wmf.transformer.transform('hideTables', document, %d, '%@', '%@', '%@');",
         self.article.isMain,
         [self apostropheEscapedArticleLanguageLocalizedStringForKey:@"info-box-title"],
         [self apostropheEscapedArticleLanguageLocalizedStringForKey:@"table-title-other"],
         [self apostropheEscapedArticleLanguageLocalizedStringForKey:@"info-box-close-text"]
        ];
}

- (void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message {
    if ([message.name isEqualToString:@"peek"]) {
        self.peekURLString = message.body[@"touchedElementURL"];
    } else if ([message.name isEqualToString:@"lateJavascriptTransforms"]) {
        if ([message.body isEqualToString:@"collapseTables"]) {
            [self.webView evaluateJavaScript:[self tableTransformJS] completionHandler:nil];
        } else if ([message.body isEqualToString:@"setLanguage"]) {
            MWLanguageInfo* languageInfo = [MWLanguageInfo languageInfoForCode:self.article.site.language];
            NSString* uidir              = ([[UIApplication sharedApplication] wmf_isRTL] ? @"rtl" : @"ltr");

            [self.webView evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.utilities.setLanguage('%@', '%@', '%@')",
                                              languageInfo.code,
                                              languageInfo.dir,
                                              uidir
             ] completionHandler:nil];
        } else if ([message.body isEqualToString:@"setPageProtected"] && !self.article.editable) {
            [self.webView evaluateJavaScript:@"window.wmf.utilities.setPageProtected()" completionHandler:nil];
        }
    } else if ([message.name isEqualToString:@"sendJavascriptConsoleLogMessageToXcodeConsole"]) {
#if DEBUG
        NSLog(@"\n\nMessage from Javascript console:\n\t%@\n\n", message.body[@"message"]);
#endif
    } else if ([message.name isEqualToString:@"articleState"]) {
        if ([message.body isEqualToString:@"articleLoaded"]) {
            //Need to introduce a delay here or the webview still might not be loaded.
            //dispatchOnMainQueueAfterDelayInSeconds(0.1, ^{
            NSAssert(self.article, @"Article not set - may need to use the old 0.1 second delay...");
            [self.delegate webViewController:self didLoadArticle:self.article];

            [self.headerHeight setOffset:[self headerHeightForCurrentTraitCollection]];

            // Force the bounds observers to fire - otherwise the html padding isn't added on article refresh.
            self.headerView.bounds          = self.headerView.bounds;
            self.footerContainerView.bounds = self.footerContainerView.bounds;
        }
    } else if ([message.name isEqualToString:@"clicks"]) {
        if (message.body[@"linkClicked"]) {
            if (self.isPeeking) {
                self.isPeeking = NO;
                return;
            }

            NSString* href = message.body[@"linkClicked"][@"href"]; //payload[@"href"];

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
        } else if (message.body[@"imageClicked"]) {
            NSNumber* imageWidth  = message.body[@"imageClicked"][@"width"];
            NSNumber* imageHeight = message.body[@"imageClicked"][@"height"];
            CGSize imageSize      = CGSizeMake(imageWidth.floatValue, imageHeight.floatValue);
            if (![MWKImage isSizeLargeEnoughForGalleryInclusion:imageSize]) {
                return;
            }

            NSString* selectedImageURL = message.body[@"imageClicked"][@"url"];
            NSCParameterAssert(selectedImageURL.length);
            if (!selectedImageURL.length) {
                DDLogError(@"Image clicked callback invoked with empty URL: %@", message.body[@"imageClicked"]);
                return;
            }

            [self.delegate webViewController:self didTapImageWithSourceURLString:selectedImageURL];
        } else if (message.body[@"referenceClicked"]) {
            [self referencesShow:message.body[@"referenceClicked"]];
        } else if (message.body[@"editClicked"]) {
            NSUInteger sectionIndex = (NSUInteger)[message.body[@"editClicked"][@"sectionId"] integerValue];
            if (sectionIndex < [self.article.sections count]) {
                [self.delegate webViewController:self didTapEditForSection:self.article.sections[sectionIndex]];
            }
        } else if (message.body[@"nonAnchorTouchEndedWithoutDragging"]) {
            [self referencesHide];
        }
    }
}

- (WKWebViewConfiguration*)configuration {
    WKUserContentController* userContentController = [[WKUserContentController alloc] init];

    [userContentController addUserScript:[[WKUserScript alloc] initWithSource:@"window.webkit.messageHandlers.lateJavascriptTransforms.postMessage('collapseTables');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES]];

    [userContentController addUserScript:[[WKUserScript alloc] initWithSource:@"window.webkit.messageHandlers.lateJavascriptTransforms.postMessage('setPageProtected');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES]];

    [userContentController addUserScript:[[WKUserScript alloc] initWithSource:@"window.webkit.messageHandlers.lateJavascriptTransforms.postMessage('setLanguage');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES]];

    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"lateJavascriptTransforms"];

    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"peek"];

    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"clicks"];

    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"sendJavascriptConsoleLogMessageToXcodeConsole"];

    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"articleState"];

    NSString* earlyJavascriptTransforms = @""
                                          "window.wmf.transformer.transform( 'hideRedlinks', document );"
                                          "window.wmf.transformer.transform( 'disableFilePageEdit', document );"
                                          "window.wmf.transformer.transform( 'addImageOverflowXContainers', document );"
                                          // 'addImageOverflowXContainers' needs to happen before 'widenImages'.
                                          // See "enwiki > Counties of England > Scope and structure > Local government"
                                          "window.wmf.transformer.transform( 'widenImages', document );"
                                          "window.wmf.transformer.transform( 'moveFirstGoodParagraphUp', document );"
                                          "window.webkit.messageHandlers.articleState.postMessage('articleLoaded');"
                                          "console.log = function(message){window.webkit.messageHandlers.sendJavascriptConsoleLogMessageToXcodeConsole.postMessage({'message': message});};";

    [userContentController addUserScript:
     [[WKUserScript alloc] initWithSource:earlyJavascriptTransforms
                            injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                         forMainFrameOnly:YES]];


    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    return configuration;
}

- (WKWebView*)webView {
    if (!_webView) {
        _webView                     = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[self configuration]];
        _webView.scrollView.delegate = self;
    }
    return _webView;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.isPeeking = NO;
    [self addHeaderView];
    [self addFooterView];

    self.referencesHidden = YES;

    self.view.clipsToBounds = NO;

    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView insertSubview:self.webView atIndex:0];
    [self.webView mas_makeConstraints:^(MASConstraintMaker* make) {
        make.leading.trailing.top.and.bottom.equalTo(self.containerView);
    }];
    self.webView.clipsToBounds            = NO;
    self.webView.scrollView.clipsToBounds = NO;

    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    self.webView.scrollView.backgroundColor  = [UIColor wmf_articleBackgroundColor];

    self.zeroStatusLabel.font = [UIFont systemFontOfSize:ALERT_FONT_SIZE];
    self.zeroStatusLabel.text = @"";

    self.webView.backgroundColor = [UIColor whiteColor];

    self.view.backgroundColor = CHROME_COLOR;

    [self observeTopAndBottomNativeViewFrames];

    [self displayArticle];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WMFZeroDispositionDidChange object:nil];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Observations

/**
 *  Observe changes to the native header and footer so we can message back to the html to add top and bottom padding to html body tag
 */
- (void)unobserveTopAndBottomNativeViewFrames {
    [self.KVOControllerNonRetaining unobserve:self.headerView];
    [self.KVOControllerNonRetaining unobserve:self.footerContainerView];
}

- (void)observeTopAndBottomNativeViewFrames {
    [self.KVOControllerNonRetaining observe:self.headerView
                                    keyPath:WMF_SAFE_KEYPATH(self.headerView, bounds)
                                    options:NSKeyValueObservingOptionInitial
                                      block:^(WebViewController* observer, UIView* view, NSDictionary* change) {
        if (!view) {
            return;
        }
        NSInteger height = (NSInteger)(floor(view.bounds.size.height));
        NSString* js =
            [NSString stringWithFormat:@""
             "document.getElementsByTagName('BODY')[0].style.paddingTop = '%ldpx';"
             , (long)height];
        if (observer.webView) {
            [observer.webView evaluateJavaScript:js completionHandler:nil];
        }
    }];

    [self.KVOControllerNonRetaining observe:self.footerContainerView
                                    keyPath:WMF_SAFE_KEYPATH(self.footerContainerView, bounds)
                                    options:NSKeyValueObservingOptionInitial
                                      block:^(WebViewController* observer, UIView* view, NSDictionary* change) {
        if (!view) {
            return;
        }
        NSInteger height = (NSInteger)(floor(view.bounds.size.height));
        NSString* js =
            [NSString stringWithFormat:@""
             "document.getElementsByTagName('BODY')[0].style.paddingBottom = '%ldpx';"
             , (long)height];
        if (observer.webView) {
            [observer.webView evaluateJavaScript:js completionHandler:nil];
        }
    }];
}

#pragma mark - UIScrollViewDelegate

/**
 *  This must be done to work around a bug in WKWebview that
 *  resets the deceleration rate each time dragging begins
 *  http://stackoverflow.com/questions/31369538/cannot-change-wkwebviews-scroll-rate-on-ios-9-beta
 */
- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
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
        make.bottom.equalTo([[self.webView wmf_browserView] mas_bottom]);
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

- (void)scrollToFragment:(NSString*)fragment {
    [self scrollToFragment:fragment animated:YES];
}

- (void)scrollToFragment:(NSString*)fragment animated:(BOOL)animated {
    if (fragment.length == 0) {
        // No section so scroll to top. (Used when "Introduction" is selected.)
        [self.webView.scrollView scrollRectToVisible:CGRectMake(0, 1, 1, 1) animated:animated];
    } else {
        if (!animated) {
            [self.webView evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.utilities.scrollToFragment('%@')", fragment] completionHandler:nil];
            return;
        }
        [self.webView getScrollViewRectForHtmlElementWithId:fragment completion:^(CGRect rect) {
            if (!CGRectIsNull(rect)) {
                [self.webView.scrollView wmf_safeSetContentOffset:CGPointMake(self.webView.scrollView.contentOffset.x, rect.origin.y)
                                                         animated:YES];
            }
        }];
    }
}

- (void)scrollToSection:(MWKSection*)section animated:(BOOL)animated {
    [self scrollToFragment:section.anchor animated:animated];
}

- (void)accessibilityCursorToSection:(MWKSection*)section {
    // This might shift the visual scroll position. To prevent it affecting other users,
    // we will only do it when we detect than an assistive technology which actually needs this is running.
    if (UIAccessibilityIsVoiceOverRunning()) {
        [self.webView evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.utilities.accessibilityCursorToFragment('%@')", section.anchor] completionHandler:nil];
    }
}

- (void)getCurrentVisibleSectionCompletion:(void (^)(MWKSection* _Nullable, NSError* __nullable error))completion {
    [self.webView getIndexOfTopOnScreenElementWithPrefix:@"section_heading_and_content_block_" count:self.article.sections.count completion:^(id obj, NSError* error){
        if (error) {
            completion(nil, error);
        } else {
            NSInteger indexOfFirstOnscreenSection = ((NSNumber*)obj).integerValue;
            completion(indexOfFirstOnscreenSection == NSNotFound ? nil : self.article.sections[indexOfFirstOnscreenSection], error);
        }
    }];
}

- (void)scrollToVerticalOffset:(CGFloat)offset {
    [self.webView.scrollView wmf_safeSetContentOffset:CGPointMake(0, offset) animated:NO];
}

- (CGFloat)currentVerticalOffset {
    return self.webView.scrollView.contentOffset.y;
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

    [self.webView loadHTML:[self.article articleHTML] withAssetsFile:@"index.html"];

    UIMenuItem* shareSnippet = [[UIMenuItem alloc] initWithTitle:MWLocalizedString(@"share-a-fact-share-menu-item", nil)
                                                          action:@selector(shareMenuItemTapped:)];
    [UIMenuController sharedMenuController].menuItems = @[shareSnippet];

    [self.footerLicenseView setLicenseTextForSite:self.article.site];
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
    // Highlight the tapped reference.
    NSString* eval = [NSString stringWithFormat:@"\
                      document.getElementById('%@').oldBackgroundColor = document.getElementById('%@').style.backgroundColor;\
                      document.getElementById('%@').style.backgroundColor = '#999';\
                      document.getElementById('%@').style.borderRadius = 2;\
                      ", linkID, linkID, linkID, linkID];
    [self.webView evaluateJavaScript:eval completionHandler:NULL];

    // Scroll the tapped reference up if the panel would cover it.
    [self.webView getScreenRectForHtmlElementWithId:linkID completion:^(CGRect rect) {
        if (!CGRectIsNull(rect)) {
            CGFloat vSpaceAboveRefsPanel = self.view.bounds.size.height - referenceViewController.panelHeight;
            // Only scroll up if the refs link would be below the refs panel.
            if ((rect.origin.y + rect.size.height) > (vSpaceAboveRefsPanel)) {
                // Calculate the distance needed to scroll the refs link to the vertical center of the
                // part of the article web view not covered by the refs panel.
                CGFloat distanceFromVerticalCenter = ((vSpaceAboveRefsPanel) / 2.0) - (rect.size.height / 2.0);
                [self.webView.scrollView wmf_safeSetContentOffset:
                 CGPointMake(
                     self.webView.scrollView.contentOffset.x,
                     self.webView.scrollView.contentOffset.y + (rect.origin.y - distanceFromVerticalCenter)
                     )
                                                         animated:YES];
            }
        }
    }];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didFinishShowingReferenceWithLinkID:(NSString*)linkID {
    NSString* eval = [NSString stringWithFormat:@"\
                      document.getElementById('%@').style.backgroundColor = document.getElementById('%@').oldBackgroundColor;\
                      ", linkID, linkID];
    [self.webView evaluateJavaScript:eval completionHandler:NULL];
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
    [self getSelectedText:^(NSString* _Nonnull text) {
        [self shareSnippet:text];
    }];
}

#pragma mark - Sharing

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(shareSnippet:)) {
        [self getSelectedText:^(NSString* _Nonnull text) {
            [self.delegate webViewController:self didSelectText:text];
        }];
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)getSelectedText:(void (^)(NSString* text))completion {
    [self.webView evaluateJavaScript:@"window.getSelection().toString()" completionHandler:^(id _Nullable obj, NSError* _Nullable error) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString* selectedText = [(NSString*)obj wmf_shareSnippetFromText];
            selectedText = selectedText.length < kMinimumTextSelectionLength ? @"" : selectedText;
            completion(selectedText);
        } else {
            completion(@"");
        }
    }];
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
    [self.webView evaluateJavaScript:[NSString stringWithFormat:@"document.querySelector('body').style['-webkit-text-size-adjust'] = '%ld%%';", fontSize.integerValue] completionHandler:NULL];
    [[NSUserDefaults standardUserDefaults] wmf_setReadingFontSize:fontSize];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end




@interface WMFWebView : WKWebView

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

