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

#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIViewController+WMFStoryboardUtilities.h"

#import "WMFShareCardViewController.h"
#import "WKWebView+WMFSuppressSelection.h"
#import "PageHistoryViewController.h"

#import "WKWebView+ElementLocation.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "UIScrollView+WMFContentOffsetUtils.h"

#import "WMFZeroMessage.h"
#import "WKWebView+LoadAssetsHtml.h"
#import "WKWebView+WMFWebViewControllerJavascript.h"
#import "WKProcessPool+WMFSharedProcessPool.h"
#import "WMFPeekHTMLElement.h"
#import "NSURL+WMFProxyServer.h"
#import "WMFImageTag.h"
#import "WKScriptMessage+WMFScriptMessage.h"
#import "WMFFindInPageKeyboardBar.h"
#import "UIView+WMFDefaultNib.h"


typedef NS_ENUM (NSInteger, WMFWebViewAlertType) {
    WMFWebViewAlertZeroWebPage,
    WMFWebViewAlertZeroCharged,
    WMFWebViewAlertZeroInterstitial
};

typedef NS_ENUM (NSUInteger, WMFFindInPageScrollDirection) {
    WMFFindInPageScrollDirectionNext,
    WMFFindInPageScrollDirectionPrevious
};

NSString* const WMFCCBySALicenseURL =
    @"https://creativecommons.org/licenses/by-sa/3.0/";

@interface WebViewController () <ReferencesVCDelegate, WKScriptMessageHandler, UIScrollViewDelegate, WMFFindInPageKeyboardBarDelegate>

@property (nonatomic, strong) MASConstraint* headerHeight;
@property (nonatomic, strong) UIView* footerContainerView;
@property (nonatomic, strong) NSMutableDictionary* footerViewHeadersByIndex;
@property (nonatomic, strong) WMFArticleFooterView* footerLicenseView;
@property (nonatomic, strong) IBOutlet UIView* containerView;

@property (strong, nonatomic) MASConstraint* footerContainerViewTopConstraint;

@property (nonatomic, strong) NSArray* findInPageMatches;
@property (nonatomic) NSInteger findInPageSelectedMatchIndex;
@property (nonatomic) BOOL disableMinimizeFindInPage;
@property (nonatomic, readwrite, retain) WMFFindInPageKeyboardBar *inputAccessoryView;

@end

@implementation WebViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self unobserveFooterContainerViewBounds];
    [self unobserveScrollViewContentSize];
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

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message {

    WMFWKScriptMessageType messageType = [WKScriptMessage wmf_typeForMessageName:message.name];
    id safeMessageBody = [message wmf_safeMessageBodyForType:messageType];

    switch (messageType) {
        case WMFWKScriptMessagePeek:
            [self handlePeekScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageConsoleMessage:
            [self handleMessageConsoleScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageClickLink:
            [self handleClickLinkScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageClickImage:
            [self handleClickImageScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageClickReference:
            [self handleClickReferenceScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageClickEdit:
            [self handleClickEditScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageNonAnchorTouchEndedWithoutDragging:
            [self handleNonAnchorTouchEndedWithoutDraggingScriptMessage];
            break;
        case WMFWKScriptMessageLateJavascriptTransform:
            [self handleLateJavascriptTransformScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageArticleState:
            [self handleArticleStateScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageFindInPageMatchesFound:
            [self handleFindInPageMatchesFoundMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageUnknown:
            NSAssert(NO, @"Unhandled script message type!");
            break;
    }
}

- (void)handlePeekScriptMessage:(NSDictionary*)messageDict {
    if(messageDict[@"tagName"]){
        self.peekElement = [[WMFPeekHTMLElement alloc] initWithTagName:messageDict[@"tagName"]
                                                                   src:messageDict[@"src"]
                                                                  href:messageDict[@"href"]];
    }else{
        self.peekElement = nil;
    }
}

- (void)handleMessageConsoleScriptMessage:(NSDictionary*)messageDict {
    DDLogDebug(@"\n\nMessage from Javascript console:\n\t%@\n\n", messageDict[@"message"]);
}

- (void)handleClickLinkScriptMessage:(NSDictionary*)messageDict {
    [self hideFindInPageWithCompletion:^{
        if (self.isPeeking) {
            self.isPeeking = NO;
            return;
        }
        
        NSString* href = messageDict[@"href"];
        
        if(href.length == 0){
            return;
        }
        
        if (!self.referencesHidden) {
            [self referencesHide];
        }
        
        if ([href wmf_isWikiResource]) {
            NSURL* url = [NSURL URLWithString:href];
            if(!url.wmf_domain){
                url = [NSURL wmf_URLWithSiteURL:self.article.url escapedDenormalizedInternalLink:href];
            }
            url = [url wmf_urlByPrependingSchemeIfSchemeless];
            [(self).delegate webViewController:(self) didTapOnLinkForArticleURL:url];
        } else {
            // A standard external link, either explicitly http(s) or left protocol-relative on web meaning http(s)
            if ([href hasPrefix:@"#"]) {
                [self scrollToFragment:[href substringFromIndex:1]];
            } else {
                if ([href hasPrefix:@"//"]) {
                    // Expand protocol-relative link to https -- secure by default!
                    href = [@"https:" stringByAppendingString:href];
                }
                NSURL* url = [NSURL URLWithString:href];
                NSCAssert(url, @"Failed to from URL from link %@", href);
                if (url) {
                    [self wmf_openExternalUrl:url];
                }
            }
        }
    }];
}

- (void)handleClickImageScriptMessage:(NSDictionary*)messageDict {
    WMFImageTag* imageTagClicked = [[WMFImageTag alloc] initWithSrc:messageDict[@"src"]
                                                             srcset:nil
                                                                alt:nil
                                                              width:messageDict[@"width"]
                                                             height:messageDict[@"height"]
                                                      dataFileWidth:messageDict[@"data-file-width"]
                                                     dataFileHeight:messageDict[@"data-file-height"]
                                                            baseURL:nil];
    
    if (imageTagClicked == nil) {
        //yes, this would have caught in the if below, but keeping this here in case that check ever goes away
        return;
    }
    
    if (![imageTagClicked isSizeLargeEnoughForGalleryInclusion]) {
        return;
    }
    
    NSString* selectedImageSrcURLString = messageDict[@"src"];
    NSCParameterAssert(selectedImageSrcURLString.length);
    if (!selectedImageSrcURLString.length) {
        DDLogError(@"Image clicked callback invoked with empty src url: %@", messageDict);
        return;
    }
    
    NSURL* selectedImageURL = [NSURL URLWithString:selectedImageSrcURLString];
    
    selectedImageURL = [selectedImageURL wmf_imageProxyOriginalSrcURL];
    
    [self.delegate webViewController:self didTapImageWithSourceURL:selectedImageURL];
}

- (void)handleClickReferenceScriptMessage:(NSDictionary*)messageDict {
    [self hideFindInPageWithCompletion:^{
        [self referencesShow:messageDict];
    }];
}

- (void)handleClickEditScriptMessage:(NSDictionary*)messageDict {
    [self hideFindInPageWithCompletion:^{
        NSUInteger sectionIndex = (NSUInteger)[messageDict[@"sectionId"] integerValue];
        if (sectionIndex < [self.article.sections count]) {
            [self.delegate webViewController:self didTapEditForSection:self.article.sections[sectionIndex]];
        }
    }];
}

- (void)handleNonAnchorTouchEndedWithoutDraggingScriptMessage {
    [self hideFindInPageWithCompletion:^{
        [self referencesHide];
    }];
}

- (void)handleLateJavascriptTransformScriptMessage:(NSString*)messageString {
    if ([messageString isEqualToString:@"collapseTables"]) {
        [self.webView wmf_collapseTablesForArticle:self.article];
    } else if ([messageString isEqualToString:@"setLanguage"]) {
        [self.webView wmf_setLanguage:[MWLanguageInfo languageInfoForCode:self.article.url.wmf_language]];
    } else if ([messageString isEqualToString:@"setPageProtected"] && !self.article.editable) {
        [self.webView wmf_setPageProtected];
    }
}

- (void)handleArticleStateScriptMessage:(NSString*)messageString {
    if ([messageString isEqualToString:@"articleLoaded"]) {
        NSAssert(self.article, @"Article not set - may need to use the old 0.1 second delay...");
        [self.delegate webViewController:self didLoadArticle:self.article];
        
        [UIView animateWithDuration:0.3
                              delay:0.5f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.headerView.alpha = 1.f;
                             self.footerContainerView.alpha = 1.f;
                         } completion:^(BOOL done) {
                         }];
        [self forceUpdateWebviewPaddingForFooters];
    }
}

- (void)handleFindInPageMatchesFoundMessage:(NSArray*)messageArray {
    self.findInPageMatches = messageArray;
    self.findInPageSelectedMatchIndex = -1;
}

#pragma mark - Find-in-page

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (WMFFindInPageKeyboardBar *)inputAccessoryView {
    if(!_inputAccessoryView) {
        _inputAccessoryView = [WMFFindInPageKeyboardBar wmf_viewFromClassNib];
        _inputAccessoryView.delegate = self;
    }
    return _inputAccessoryView;
}

- (WMFFindInPageKeyboardBar *)findInPageKeyboardBar {
    return self.view.inputAccessoryView;
}

- (void)showFindInPage {
    [self referencesHide];
    [self becomeFirstResponder];
    [[self findInPageKeyboardBar] show];
}

- (void)hideFindInPageWithCompletion:(nullable dispatch_block_t)completion {
    [self resetFindInPageWithCompletion:^{
        [[self findInPageKeyboardBar] hide];
        [self resignFirstResponder];
        if (completion) {
            completion();
        }
    }];
}

- (void)resetFindInPageWithCompletion:(nullable dispatch_block_t)completion {
    [self.webView evaluateJavaScript:@"window.wmf.findInPage.removeSearchTermHighlights()" completionHandler:^(id obj, NSError* _Nullable error) {
        self.findInPageMatches = @[];
        self.findInPageSelectedMatchIndex = -1;
        [[self findInPageKeyboardBar] reset];
        if (completion) {
            completion();
        }
    }];
}

- (void)minimizeFindInPage {
    if (!self.disableMinimizeFindInPage) {
        [[self findInPageKeyboardBar] hide];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.disableMinimizeFindInPage = YES;
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.disableMinimizeFindInPage = NO;
    }];
}

- (void)setFindInPageMatches:(NSArray *)findInPageMatches {
    _findInPageMatches = findInPageMatches;
    [self updateFindInPageKeyboardBarLabel];
}

#pragma FindInPage label

- (void)updateFindInPageKeyboardBarLabel {
    [[self findInPageKeyboardBar] updateLabelTextForCurrentMatchIndex:self.findInPageSelectedMatchIndex
                                                         matchesCount:self.findInPageMatches.count];
}

#pragma FindInPageBar selected match

- (void)setFindInPageSelectedMatchIndex:(NSInteger)findInPageSelectedMatchIndex {
    _findInPageSelectedMatchIndex = findInPageSelectedMatchIndex;
    [self updateFindInPageKeyboardBarLabel];
}

- (void)moveFindInPageSelectedMatchIndexInDirection:(WMFFindInPageScrollDirection)direction {
    if(self.findInPageMatches.count == 0){
        return;
    }
    switch (direction) {
        case WMFFindInPageScrollDirectionNext:
            self.findInPageSelectedMatchIndex += 1;
            if (self.findInPageSelectedMatchIndex >= self.findInPageMatches.count) {
                self.findInPageSelectedMatchIndex = 0;
            }
            break;
        case WMFFindInPageScrollDirectionPrevious:
            self.findInPageSelectedMatchIndex -= 1;
            if (self.findInPageSelectedMatchIndex < 0) {
                self.findInPageSelectedMatchIndex = self.findInPageMatches.count - 1;
            }
            break;
    }
}

- (void)scrollToAndFocusOnSelectedMatch {
    if(self.findInPageMatches.count == 0){
        return;
    }
    NSString* matchSpanId = [self.findInPageMatches wmf_safeObjectAtIndex:self.findInPageSelectedMatchIndex];
    if (matchSpanId == nil) {
        return;
    }
    @weakify(self);
    [self.webView getScrollViewRectForHtmlElementWithId:matchSpanId completion:^(CGRect rect){
        @strongify(self);
        [UIView animateWithDuration:0.3
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             @strongify(self);
                             self.disableMinimizeFindInPage = YES;
                             
//TODO: modified to scroll the match to the vertical point between top of keyboard and top of screen
                             
                             [self.webView.scrollView wmf_safeSetContentOffset:CGPointMake(self.webView.scrollView.contentOffset.x, fmaxf(rect.origin.y - 80.f, 0.f)) animated:NO];
                         } completion:^(BOOL done) {
                             self.disableMinimizeFindInPage = NO;
                         }];
    }];
    
    [self.webView evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.findInPage.useFocusStyleForHighlightedSearchTermWithId('%@')", matchSpanId] completionHandler:nil];
}

- (void)scrollToAndFocusOnFirstMatch {
    self.findInPageSelectedMatchIndex = -1;
    [self keyboardBarNextButtonTapped:nil];
}

#pragma FindInPageKeyboardBarDelegate

- (void)keyboardBar:(WMFFindInPageKeyboardBar*)keyboardBar searchTermChanged:(NSString *)term {
    [self.webView evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.findInPage.findAndHighlightAllMatchesForSearchTerm('%@')", term] completionHandler:^(id _Nullable obj, NSError* _Nullable error) {
        [self scrollToAndFocusOnFirstMatch];
    }];
}

- (void)keyboardBarCloseButtonTapped:(WMFFindInPageKeyboardBar*)keyboardBar {
    [self hideFindInPageWithCompletion:nil];
}

- (void)keyboardBarClearButtonTapped:(WMFFindInPageKeyboardBar*)keyboardBar {
    [self resetFindInPageWithCompletion:nil];
}

- (void)keyboardBarPreviousButtonTapped:(WMFFindInPageKeyboardBar*)keyboardBar {
    [self moveFindInPageSelectedMatchIndexInDirection:WMFFindInPageScrollDirectionPrevious];
    [self scrollToAndFocusOnSelectedMatch];
}

- (void)keyboardBarNextButtonTapped:(WMFFindInPageKeyboardBar*)keyboardBar {
    [self moveFindInPageSelectedMatchIndexInDirection:WMFFindInPageScrollDirectionNext];
    [self scrollToAndFocusOnSelectedMatch];
}

#pragma mark - WebView configuration

- (WKWebViewConfiguration*)configuration {
    WKUserContentController* userContentController = [[WKUserContentController alloc] init];

    [userContentController addUserScript:[[WKUserScript alloc] initWithSource:@"window.webkit.messageHandlers.lateJavascriptTransform.postMessage('collapseTables');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES]];

    [userContentController addUserScript:[[WKUserScript alloc] initWithSource:@"window.webkit.messageHandlers.lateJavascriptTransform.postMessage('setPageProtected');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES]];

    [userContentController addUserScript:[[WKUserScript alloc] initWithSource:@"window.webkit.messageHandlers.lateJavascriptTransform.postMessage('setLanguage');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES]];

    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"lateJavascriptTransform"];

    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"peek"];
    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"linkClicked"];
    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"imageClicked"];
    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"referenceClicked"];
    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"editClicked"];
    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"nonAnchorTouchEndedWithoutDragging"];

    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"sendJavascriptConsoleLogMessageToXcodeConsole"];

    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"articleState"];
    
    [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:@"findInPageMatchesFound"];

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
    configuration.processPool           = [WKProcessPool wmf_sharedProcessPool];
    return configuration;
}

- (WKWebView*)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[self configuration]];
        _webView.scrollView.delegate = self;
    }
    return _webView;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isPeeking = NO;

    [self addFooterContainerView];
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

    [self observeFooterContainerViewBounds];
    [self observeScrollViewContentSize];

    [self displayArticle];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.webView.scrollView wmf_shouldScrollToTopOnStatusBarTap:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    self.webView.scrollView.delegate = self;
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateZeroStateWithNotification:)
                                                 name:WMFZeroDispositionDidChange
                                               object:nil];
    // should happen in will appear to prevent bar from being incorrect during transitions
    [self updateZeroState];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveOpenArticleTitleWithCurrentlyOnscreenFragment)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)saveOpenArticleTitleWithCurrentlyOnscreenFragment {
    if (self.navigationController.topViewController == self.parentViewController) { // Ensure only the topmost article is recorded.
        [self getCurrentVisibleSectionCompletion:^(MWKSection* visibleSection, NSError* error){
            NSURL* url = [self.article.url wmf_URLWithFragment:visibleSection.anchor];
            [[NSUserDefaults standardUserDefaults] wmf_setOpenArticleURL:url];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    self.webView.scrollView.delegate = nil;
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WMFZeroDispositionDidChange object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Observations

/**
 *  Observe changes to the native footer bounds so we can message back to the html to
 *  add bottom padding to html body tag to make room for the native footerContainerView overlay.
 */
- (void)unobserveFooterContainerViewBounds {
    [self.KVOControllerNonRetaining unobserve:self.footerContainerView
                                      keyPath:WMF_SAFE_KEYPATH(self.footerContainerView, bounds)];
}

- (void)observeFooterContainerViewBounds {
    [self.KVOControllerNonRetaining observe:self.footerContainerView
                                    keyPath:WMF_SAFE_KEYPATH(self.footerContainerView, bounds)
                                    options:NSKeyValueObservingOptionInitial
                                      block:^(WebViewController* observer, UIView* view, NSDictionary* change) {
        if (view && observer.webView) {
            [observer.webView wmf_setBottomPadding:(NSInteger)(ceil(view.bounds.size.height))];
        }
    }];
}

/**
 *  Observe changes to web view scroll view's content size so we can set the top constraint
 *  of the native footerContainerView. Reminder: we constrain to top of footerContainerView
 *  because constraining its bottom to the WKContentView's bottom is flakey - ie doesn't
 *  always work.
 */
- (void)unobserveScrollViewContentSize {
    [self.KVOControllerNonRetaining unobserve:self.webView.scrollView
                                      keyPath:WMF_SAFE_KEYPATH(self.webView.scrollView, contentSize)];
}

- (void)observeScrollViewContentSize {
    @weakify(self);
    [self.KVOControllerNonRetaining observe:self.webView.scrollView
                                    keyPath:WMF_SAFE_KEYPATH(self.webView.scrollView, contentSize)
                                    options:NSKeyValueObservingOptionInitial
                                      block:^(WebViewController* observer, UIScrollView* scrollView, NSDictionary* change) {
        @strongify(self);
        [self setTopOfFooterContainerViewForContentSize:scrollView.contentSize];
    }];
}

- (void)setTopOfFooterContainerViewForContentSize:(CGSize)contentSize {
    self.footerContainerViewTopConstraint.offset = contentSize.height - self.footerContainerView.bounds.size.height;
}

#pragma mark - UIScrollViewDelegate

/**
 *  This must be done to work around a bug in WKWebview that
 *  resets the deceleration rate each time dragging begins
 *  http://stackoverflow.com/questions/31369538/cannot-change-wkwebviews-scroll-rate-on-ios-9-beta
 */
- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    [self referencesHide];
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

- (UIView*)footerAtIndex:(NSInteger)index {
    UIView* footerView       = self.footerViewControllers[index].view;
    UIView* footerViewHeader = self.footerViewHeadersByIndex[@(index)];
    return footerViewHeader ? : footerView;
}

- (void)scrollToFooterAtIndex:(NSInteger)index {
    UIView* viewToScrollTo   = [self footerAtIndex:index];
    CGPoint footerViewOrigin = [self.webView.scrollView convertPoint:viewToScrollTo.frame.origin
                                                            fromView:self.footerContainerView];
    footerViewOrigin.y -= self.webView.scrollView.contentInset.top;
    [self.webView.scrollView setContentOffset:footerViewOrigin animated:YES];
}

- (void)accessibilityCursorToFooterAtIndex:(NSInteger)index {
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
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webView.scrollView addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker* make) {
        // lead/trail must be constained to webview, the scrollview doesn't define a width
        make.leading.and.trailing.equalTo(self.webView);
        make.top.equalTo(self.webView.scrollView);
        self.headerHeight = make.height.equalTo(@(0));
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
    if ([self.article.url wmf_isNonStandardURL]) {
        return;
    }
    self.footerViewHeadersByIndex = [NSMutableDictionary dictionary];
    [self addFooterContentViews];
    [self.footerContainerView wmf_recursivelyDisableScrollsToTop];
}

- (void)addFooterContainerView {
    self.footerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webView.scrollView addSubview:self.footerContainerView];
    [self.footerContainerView mas_makeConstraints:^(MASConstraintMaker* make) {
        // lead/trail must be constained to webview, the scrollview doesn't define a width
        make.leading.and.trailing.equalTo(self.webView);

        // Note: Can't constrain bottom to webView's WKContentView bottom
        // because its bottom constraint doesnt' seem to always track with
        // the actual bottom of the page. This was causing the footer to
        // *sometimes* not be at the bottom - was flakey on large pages.
        self.footerContainerViewTopConstraint = make.top.equalTo(self.webView.scrollView);
    }];
}

- (void)addFooterContentViews {
    if ([self.article.url wmf_isNonStandardURL]) {
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
            header.translatesAutoresizingMaskIntoConstraints = NO;
            [self.footerContainerView addSubview:header];
            [header mas_remakeConstraints:^(MASConstraintMaker* make) {
                make.leading.and.trailing.equalTo(self.footerContainerView);
                make.top.equalTo(topAnchor);
            }];
            topAnchor = header.mas_bottom;
        }

        childVC.view.translatesAutoresizingMaskIntoConstraints = NO;
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

    self.footerLicenseView.translatesAutoresizingMaskIntoConstraints = NO;
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

- (CGFloat)headerHeightForCurrentArticle {
    if (self.article.isMain || !self.article.imageURL || [self.article.url wmf_isNonStandardURL]) {
        return 0;
    } else {
        return 210;
    }
}

- (void)forceUpdateWebviewPaddingForFooters {
    self.footerContainerView.bounds = self.footerContainerView.bounds;
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
            [self.webView wmf_scrollToFragment:fragment];
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
    [self.webView wmf_accessibilityCursorToFragment:section.anchor];
}

- (void)getCurrentVisibleSectionCompletion:(void (^)(MWKSection* _Nullable, NSError* __nullable error))completion {
    [self.webView getIndexOfTopOnScreenElementWithPrefix:@"section_heading_and_content_block_" count:self.article.sections.count completion:^(id obj, NSError* error){
        if (error) {
            completion(nil, error);
        } else {
            NSInteger indexOfFirstOnscreenSection = ((NSNumber*)obj).integerValue;
            completion(indexOfFirstOnscreenSection == -1 ? nil : self.article.sections[indexOfFirstOnscreenSection], error);
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
    if (isnan(point.x) || isinf(point.x) || isnan(point.y) || isinf(point.y)) {
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

- (void)setArticle:(MWKArticle * _Nullable)article articleURL:(NSURL*)articleURL{
    self.articleURL = articleURL;
    self.article = article;
}


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

    self.headerView.alpha          = 0.f;
    self.footerContainerView.alpha = 0.f;
    CGFloat headerHeight = [self headerHeightForCurrentArticle];
    [self.headerHeight setOffset:headerHeight];

    [self.webView loadHTML:[self.article articleHTML] baseURL:self.article.url withAssetsFile:@"index.html" scrolledToFragment:self.articleURL.fragment topPadding:headerHeight];

    UIMenuItem* shareSnippet = [[UIMenuItem alloc] initWithTitle:MWLocalizedString(@"share-a-fact-share-menu-item", nil)
                                                          action:@selector(shareMenuItemTapped:)];
    [UIMenuController sharedMenuController].menuItems = @[shareSnippet];

    [self.footerLicenseView setLicenseTextForURL:self.article.url];
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
    [self.webView wmf_highlightLinkID:linkID];

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
    [self.webView wmf_unHighlightLinkID:linkID];
}

- (void)referenceViewControllerCloseReferences:(ReferencesVC*)referenceViewController {
    [self referencesHide];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectInternalReferenceWithFragment:(NSString*)fragment {
    [self scrollToFragment:fragment];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectReferenceWithURL:(NSURL*)url {
    [self.delegate webViewController:self didTapOnLinkForArticleURL:url];
}

- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectExternalReferenceWithURL:(NSURL*)url {
    [self wmf_openExternalUrl:url];
}

#pragma mark - Share Actions

- (void)shareMenuItemTapped:(id)sender {
    [self.webView wmf_getSelectedText:^(NSString* _Nonnull text) {
        [self shareSnippet:text];
    }];
}

#pragma mark - Sharing

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if ([[self findInPageKeyboardBar] isVisible]) {
        return NO;
    }
    
    if (action == @selector(shareSnippet:)) {
        [self.webView wmf_getSelectedText:^(NSString* _Nonnull text) {
            [self.delegate webViewController:self didSelectText:text];
        }];
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
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
    [self.webView wmf_setTextSize:fontSize.integerValue];
    [[NSUserDefaults standardUserDefaults] wmf_setReadingFontSize:fontSize];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    if ([self.delegate respondsToSelector:@selector(webViewController:scrollViewDidScroll:)]) {
        [self.delegate webViewController:self scrollViewDidScroll:scrollView];
    }
    [self minimizeFindInPage];
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

