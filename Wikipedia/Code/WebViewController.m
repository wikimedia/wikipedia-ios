#import "WebViewController_Private.h"
#import "WMFWebView.h"
#import "Wikipedia-Swift.h"
@import WebKit;
@import WMF;
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "PageHistoryViewController.h"
#import "WKWebView+ElementLocation.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "WKWebView+WMFWebViewControllerJavascript.h"
#import "WMFFindInPageKeyboardBar.h"
#import "WebViewController+WMFReferencePopover.h"
#import "WMFReferencePopoverMessageViewController.h"

typedef NS_ENUM(NSInteger, WMFWebViewAlertType) {
    WMFWebViewAlertZeroWebPage,
    WMFWebViewAlertZeroCharged,
    WMFWebViewAlertZeroInterstitial
};

typedef NS_ENUM(NSUInteger, WMFFindInPageScrollDirection) {
    WMFFindInPageScrollDirectionNext,
    WMFFindInPageScrollDirectionPrevious
};

@interface WebViewController () <WKScriptMessageHandler, UIScrollViewDelegate, WMFFindInPageKeyboardBarDelegate, UIPageViewControllerDelegate, WMFReferencePageViewAppearanceDelegate, WMFThemeable>

@property (nonatomic, strong) NSLayoutConstraint *headerHeightConstraint;
@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) NSNumber *fontSizeMultiplier;

@property (nonatomic) CGFloat marginWidth;

@property (nonatomic, strong) NSArray *findInPageMatches;
@property (nonatomic) NSInteger findInPageSelectedMatchIndex;
@property (nonatomic) BOOL disableMinimizeFindInPage;
@property (nonatomic, readwrite, retain) WMFFindInPageKeyboardBar *inputAccessoryView;
@property (weak, nonatomic) IBOutlet UIView *statusBarUnderlayView;

@property (nonatomic, strong) NSArray<WMFReference *> *lastClickedReferencesGroup;

@property (nonatomic, strong) WMFTheme *theme;

@property (nonatomic, getter=isAfterFirstUserScrollInteraction) BOOL afterFirstUserScrollInteraction;

@end

@implementation WebViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //explicitly nil these values out to remove KVO observers
    self.webView = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.session = [SessionSingleton sharedInstance];
        self.headerFadingEnabled = YES;
    }
    return self;
}

- (instancetype)init {
    return [self initWithSession:[SessionSingleton sharedInstance]];
}

- (instancetype)initWithSession:(SessionSingleton *)aSession {
    NSParameterAssert(aSession);
    self = [super init];
    if (self) {
        self.session = aSession;
        self.headerFadingEnabled = YES;
    }
    return self;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {

    WMFWKScriptMessage messageType = [WKScriptMessage wmf_typeForMessageName:message.name];
    id safeMessageBody = [message wmf_safeMessageBodyForType:messageType];

    switch (messageType) {
        case WMFWKScriptMessageJavascriptConsoleLog:
            [self handleJavascriptConsoleLogScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageLinkClicked:
            [self handleLinkClickedScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageImageClicked:
            [self handleImageClickedScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageReferenceClicked:
            [self handleReferenceClickedScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageAddTitleDescriptionClicked:
            [self handleAddTitleDescriptionClickedScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageEditClicked:
            [self handleEditClickedScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageArticleState:
            [self handleArticleStateScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageFindInPageMatchesFound:
            [self handleFindInPageMatchesFoundMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageFooterReadMoreTitlesShown:
            [self handleFooterReadMoreTitlesShownScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageFooterReadMoreSaveClicked:
            [self handleFooterReadMoreSaveClickedScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageFooterMenuItemClicked:
            [self handleFooterMenuItemClickedScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageFooterLegalLicenseLinkClicked:
            [self handleFooterLegalLicenseLinkClickedScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageFooterBrowserLinkClicked:
            [self handleFooterBrowserLinkClickedScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageFooterContainerAdded:
            [self handleFooterContainerAddedScriptMessage:safeMessageBody];
            break;
        case WMFWKScriptMessageUnknown:
            NSAssert(NO, @"Unhandled script message type!");
            break;
    }
}

- (void)handleFooterReadMoreTitlesShownScriptMessage:(NSArray *)messageArray {
    NSArray *articleURLs = [messageArray wmf_mapAndRejectNil:^id(NSString *title) {
        return [self.article.url wmf_URLWithTitle:title];
    }];
    for (NSURL *articleURL in articleURLs) {
        [self updateReadMoreSaveButtonIsSavedStateForURL:articleURL];
    }
}

- (void)handleFooterReadMoreSaveClickedScriptMessage:(NSDictionary *)messageDict {
    NSURL *articleURL = [self.article.url wmf_URLWithTitle:messageDict[@"title"]];
    if (articleURL) {
        [self toggleReadMoreSaveButtonIsSavedStateForURL:articleURL];
    }
}

- (void)handleFooterMenuItemClickedScriptMessage:(NSDictionary *)messageDict {
    NSString *messageString = messageDict[@"selection"];
    NSArray *payload = messageDict[@"payload"];

    WMFArticleFooterMenuItem item;
    if ([messageString isEqualToString:@"languages"]) {
        item = WMFArticleFooterMenuItemLanguages;
    } else if ([messageString isEqualToString:@"lastEdited"]) {
        item = WMFArticleFooterMenuItemLastEdited;
    } else if ([messageString isEqualToString:@"pageIssues"]) {
        item = WMFArticleFooterMenuItemPageIssues;
    } else if ([messageString isEqualToString:@"disambiguation"]) {
        item = WMFArticleFooterMenuItemDisambiguation;
    } else if ([messageString isEqualToString:@"coordinate"]) {
        item = WMFArticleFooterMenuItemCoordinate;
    } else if ([messageString isEqualToString:@"talkPage"]) {
        item = WMFArticleFooterMenuItemTalkPage;
    } else {
        NSAssert(false, @"Unhandled footer item type encountered");
        return;
    }
    [self.delegate webViewController:self didTapFooterMenuItem:item payload:payload];
}

- (void)handleFooterLegalLicenseLinkClickedScriptMessage:(NSString *)messageString {
    [self showLicenseButtonPressed];
}

- (void)handleFooterBrowserLinkClickedScriptMessage:(NSString *)messageString {
    [self wmf_openExternalUrl:self.articleURL];
}

- (void)updateReadMoreSaveButtonIsSavedStateForURL:(NSURL *)url {
    BOOL isSaved = [self.article.dataStore.savedPageList isSaved:url];
    NSString *title = [[url.absoluteString.lastPathComponent stringByRemovingPercentEncoding] wmf_stringBySanitizingForJavaScript];
    if (title) {
        NSString *saveTitle = [WMFCommonStrings saveTitleWithLanguage:url.wmf_language];
        NSString *savedTitle = [WMFCommonStrings savedTitleWithLanguage:url.wmf_language];
        NSString *saveButtonText = [(isSaved ? savedTitle : saveTitle)wmf_stringBySanitizingForJavaScript];
        [self.webView evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.footerReadMore.updateSaveButtonForTitle('%@', '%@', %@, document)", title, saveButtonText, (isSaved ? @"true" : @"false")] completionHandler:nil];
    }
}

- (void)toggleReadMoreSaveButtonIsSavedStateForURL:(NSURL *)url {
    BOOL isSaved = [self.article.dataStore.savedPageList toggleSavedPageForURL:url];
    [self logReadMoreSaveButtonToggle:isSaved url:url];
    [self updateReadMoreSaveButtonIsSavedStateForURL:url];
    [self.delegate webViewController:self didTapFooterReadMoreSaveForLaterForArticleURL:url didSave:isSaved];
}

- (void)handleJavascriptConsoleLogScriptMessage:(NSDictionary *)messageDict {
    DDLogDebug(@"\n\nMessage from Javascript console:\n\t%@\n\n", messageDict[@"message"]);
}

- (void)handleLinkClickedScriptMessage:(NSDictionary *)messageDict {
    [self wmf_dismissReferencePopoverAnimated:NO
                                   completion:^{
                                       [self hideFindInPageWithCompletion:^{
                                           NSString *href = messageDict[@"href"];

                                           if (href.length == 0) {
                                               return;
                                           }

                                           NSURL *url = [NSURL URLWithString:href];
                                           if (!url) {
                                               return;
                                           }

                                           if ([url wmf_isWikiResource]) {
                                               if (!url.wmf_domain) {
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
                                                   url = [NSURL URLWithString:href];
                                                   NSCAssert(url, @"Failed to from URL from link %@", href);
                                                   if (url) {
                                                       [self wmf_openExternalUrl:url];
                                                   }
                                               }
                                           }
                                       }];
                                   }];
}

- (void)handleImageClickedScriptMessage:(NSDictionary *)messageDict {
    [self wmf_dismissReferencePopoverAnimated:NO
                                   completion:^{
                                       WMFImageTag *imageTagClicked = [[WMFImageTag alloc] initWithSrc:messageDict[@"src"]
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

                                       NSString *selectedImageSrcURLString = messageDict[@"src"];
                                       NSCParameterAssert(selectedImageSrcURLString.length);
                                       if (!selectedImageSrcURLString.length) {
                                           DDLogError(@"Image clicked callback invoked with empty src url: %@", messageDict);
                                           return;
                                       }

                                       NSURL *selectedImageURL = [NSURL URLWithString:selectedImageSrcURLString];

                                       selectedImageURL = [selectedImageURL wmf_imageProxyOriginalSrcURL];

                                       [self.delegate webViewController:self didTapImageWithSourceURL:selectedImageURL];
                                   }];
}

- (void)handleReferenceClickedScriptMessage:(NSDictionary *)messageDict {
    NSAssert(messageDict[@"referencesGroup"], @"Expected key 'referencesGroup' not found in script message dictionary");
    self.lastClickedReferencesGroup = [messageDict[@"referencesGroup"] wmf_map:^id(NSDictionary *referenceDict) {
        return [[WMFReference alloc] initWithScriptMessageDict:referenceDict yOffset:self.webView.scrollView.contentInset.top];
    }];

    NSAssert(messageDict[@"selectedIndex"], @"Expected key 'selectedIndex' not found in script message dictionary");
    NSNumber *selectedIndex = messageDict[@"selectedIndex"];
    [self showReferenceFromLastClickedReferencesGroupAtIndex:selectedIndex.integerValue];
}

- (void)handleAddTitleDescriptionClickedScriptMessage:(NSDictionary *)messageDict {
    [self.delegate webViewController:self didTapAddTitleDescriptionForArticle:self.article];
}

- (void)handleEditClickedScriptMessage:(NSDictionary *)messageDict {
    [self wmf_dismissReferencePopoverAnimated:NO
                                   completion:^{
                                       [self hideFindInPageWithCompletion:^{
                                           NSUInteger sectionIndex = (NSUInteger)[messageDict[@"sectionId"] integerValue];
                                           if (sectionIndex < [self.article.sections count]) {
                                               [self.delegate webViewController:self didTapEditForSection:self.article.sections[sectionIndex]];
                                           }
                                       }];
                                   }];
}

- (void)handleArticleStateScriptMessage:(NSString *)messageString {
    if ([messageString isEqualToString:@"indexHTMLDocumentLoaded"]) {
        self.afterFirstUserScrollInteraction = NO;

        NSString *decodedFragment = [[self.articleURL fragment] stringByRemovingPercentEncoding];
        BOOL collapseTables = ![[NSUserDefaults wmf] wmf_isAutomaticTableOpeningEnabled];
        [self.webView wmf_fetchTransformAndAppendSectionsToDocument:self.article collapseTables:collapseTables scrolledTo:decodedFragment];

        [self updateWebContentMarginForSize:self.view.bounds.size force:YES];
        NSAssert(self.article, @"Article not set");
        [self.delegate webViewController:self didLoadArticle:self.article];

        if (!self.isHeaderFadingEnabled) {
            return;
        }

        [UIView animateWithDuration:0.3
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.headerView.alpha = 1;
                         }
                         completion:^(BOOL done){

                         }];
    }
}

- (void)handleFindInPageMatchesFoundMessage:(NSArray *)messageArray {
    self.findInPageMatches = messageArray;
    self.findInPageSelectedMatchIndex = -1;
}

#pragma mark - Read more save button event logging

- (void)logReadMoreSaveButtonToggle:(BOOL)isSaved url:(NSURL *)url {
    if (isSaved) {
        [self.savedPagesFunnel logSaveNewWithArticleURL:url];
    } else {
        [self.savedPagesFunnel logDeleteWithArticleURL:url];
    }
}

- (SavedPagesFunnel *)savedPagesFunnel {
    if (!_savedPagesFunnel) {
        _savedPagesFunnel = [[SavedPagesFunnel alloc] init];
    }
    return _savedPagesFunnel;
}

#pragma mark - Find-in-page

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (WMFFindInPageKeyboardBar *)inputAccessoryView {
    if (!_inputAccessoryView) {
        _inputAccessoryView = [WMFFindInPageKeyboardBar wmf_viewFromClassNib];
        _inputAccessoryView.delegate = self;
        [_inputAccessoryView applyTheme:self.theme];
    }
    return _inputAccessoryView;
}

- (WMFFindInPageKeyboardBar *)findInPageKeyboardBar {
    return self.view.inputAccessoryView;
}

- (void)showFindInPage {
    [self killScroll];
    [self becomeFirstResponder];
    [[self findInPageKeyboardBar] show];
}

- (void)killScroll {
    CGPoint offset = [self.webView.scrollView contentOffset];
    [self.webView.scrollView setContentOffset:offset animated:NO];
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
    [self.webView evaluateJavaScript:@"window.wmf.findInPage.removeSearchTermHighlights()"
                   completionHandler:^(id obj, NSError *_Nullable error) {
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

- (void)viewLayoutMarginsDidChange {
    [super viewLayoutMarginsDidChange];
    [self updateWebContentMarginForSize:self.view.bounds.size force:NO];
}

- (CGFloat)marginWidthForSize:(CGSize)size {
    UIEdgeInsets layoutMargins = self.view.layoutMargins;
    return MAX(MAX(layoutMargins.left, layoutMargins.right), floor(0.5 * size.width * (1 - self.contentWidthPercentage)));
}

- (void)handleFooterContainerAddedScriptMessage:(id)message {
    //TODO: only need to do the "window.wmf.footerContainer.updateLeftAndRightMargin" part here... may be ok though as it's not changing the other values so shouldn't cause extra reflow...
    [self updateWebContentMarginForSize:self.view.bounds.size force:YES];
}

- (void)updateWebContentMarginForSize:(CGSize)size force:(BOOL)force {
    CGFloat newMarginWidth = [self marginWidthForSize:self.view.bounds.size];
    if (force || ABS(self.marginWidth - newMarginWidth) >= 0.5) {
        self.marginWidth = newMarginWidth;
        NSString *jsFormat = @""
                              "var contentDiv = document.getElementById('content');"
                              "contentDiv.style.marginLeft='%ipx';"
                              "contentDiv.style.marginRight='%ipx';"
                              "window.wmf.footerContainer.updateLeftAndRightMargin(%i, document);"
                              "var body = document.getElementsByTagName('body')[0];"
                              "body.style.paddingTop='%ipx';";

        CGFloat marginWidth = [self marginWidthForSize:size];
        int padding = (int)MAX(0, marginWidth);
        int paddingTop = (int)[self headerHeightForCurrentArticle];
        NSString *js = [NSString stringWithFormat:jsFormat, padding, padding, padding, paddingTop];
        [self.webView evaluateJavaScript:js completionHandler:NULL];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateWebContentMarginForSize:self.view.bounds.size force:NO];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [self wmf_dismissReferencePopoverAnimated:NO completion:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.disableMinimizeFindInPage = YES;
    [coordinator animateAlongsideTransition:nil
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                                     self.disableMinimizeFindInPage = NO;
                                 }];
}

- (void)setFindInPageMatches:(NSArray *)findInPageMatches {
    _findInPageMatches = findInPageMatches;
    [self updateFindInPageKeyboardBar];
}

#pragma FindInPage label and prev / next button state

- (void)updateFindInPageKeyboardBar {
    [[self findInPageKeyboardBar] updateForCurrentMatchIndex:self.findInPageSelectedMatchIndex
                                                matchesCount:self.findInPageMatches.count];
}

#pragma FindInPageBar selected match

- (void)setFindInPageSelectedMatchIndex:(NSInteger)findInPageSelectedMatchIndex {
    _findInPageSelectedMatchIndex = findInPageSelectedMatchIndex;
    [self updateFindInPageKeyboardBar];
}

- (void)moveFindInPageSelectedMatchIndexInDirection:(WMFFindInPageScrollDirection)direction {
    if (self.findInPageMatches.count == 0) {
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
    if (self.findInPageSelectedMatchIndex >= self.findInPageMatches.count) {
        return;
    }
    NSString *matchSpanId = [self.findInPageMatches objectAtIndex:self.findInPageSelectedMatchIndex];
    if (matchSpanId == nil) {
        return;
    }
    @weakify(self);
    [self.webView getScrollViewRectForHtmlElementWithId:matchSpanId
                                             completion:^(CGRect rect) {
                                                 @strongify(self);
                                                 self.disableMinimizeFindInPage = YES;
                                                 CGFloat matchScrollOffsetY = CGRectGetMinY(rect);
                                                 CGFloat keyboardBarOriginY = [self.findInPageKeyboardBar.window convertPoint:CGPointZero fromView:self.findInPageKeyboardBar].y;
                                                 CGFloat contentInsetTop = self.webView.scrollView.contentInset.top;
                                                 CGFloat newOffsetY = matchScrollOffsetY + contentInsetTop - 0.5 * self.delegate.navigationBar.visibleHeight - 0.5 * keyboardBarOriginY + 0.5 * CGRectGetHeight(rect);
                                                 if (newOffsetY <= 0 - contentInsetTop) {
                                                     newOffsetY = 0 - contentInsetTop;
                                                     [self.delegate.navigationBar setNavigationBarPercentHidden:0 underBarViewPercentHidden:0 extendedViewPercentHidden:0 topSpacingPercentHidden:0 shadowAlpha:1 animated:YES additionalAnimations:NULL];
                                                 } else if (newOffsetY > (self.delegate.navigationBar.frame.size.height - self.delegate.navigationBar.safeAreaInsets.top)) {
                                                     [self.delegate.navigationBar setNavigationBarPercentHidden:1 underBarViewPercentHidden:1 extendedViewPercentHidden:1 topSpacingPercentHidden:1 shadowAlpha:1 animated:YES additionalAnimations:NULL];
                                                 }
                                                 CGPoint centeredOffset = CGPointMake(self.webView.scrollView.contentOffset.x, newOffsetY);
                                                 [self.webView.scrollView wmf_safeSetContentOffset:centeredOffset
                                                                                          animated:YES
                                                                                        completion:^(BOOL done) {
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

- (void)keyboardBar:(WMFFindInPageKeyboardBar *)keyboardBar searchTermChanged:(NSString *)term {
    term = [term wmf_stringBySanitizingForJavaScript];
    [self.webView evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.findInPage.findAndHighlightAllMatchesForSearchTerm('%@')", term]
                   completionHandler:^(id _Nullable obj, NSError *_Nullable error) {
                       [self scrollToAndFocusOnFirstMatch];
                   }];
}

- (void)keyboardBarCloseButtonTapped:(WMFFindInPageKeyboardBar *)keyboardBar {
    [self hideFindInPageWithCompletion:nil];
}

- (void)keyboardBarClearButtonTapped:(WMFFindInPageKeyboardBar *)keyboardBar {
    // Stop scrolling to let the keyboard open
    [self killScroll];
    [self resetFindInPageWithCompletion:nil];
}

- (void)keyboardBarPreviousButtonTapped:(WMFFindInPageKeyboardBar *)keyboardBar {
    [self moveFindInPageSelectedMatchIndexInDirection:WMFFindInPageScrollDirectionPrevious];
    [self scrollToAndFocusOnSelectedMatch];
}

- (void)keyboardBarNextButtonTapped:(WMFFindInPageKeyboardBar *)keyboardBar {
    [self moveFindInPageSelectedMatchIndexInDirection:WMFFindInPageScrollDirectionNext];
    [self scrollToAndFocusOnSelectedMatch];
}

#pragma mark - WebView configuration

- (WKWebViewConfiguration *)configuration {
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];

    NSArray *handlerNames = @[
        @"linkClicked",
        @"imageClicked",
        @"referenceClicked",
        @"addTitleDescriptionClicked",
        @"editClicked",
        @"javascriptConsoleLog",
        @"articleState",
        @"findInPageMatchesFound",
        @"footerReadMoreSaveClicked",
        @"footerReadMoreTitlesShown",
        @"footerContainerAdded",
        @"footerMenuItemClicked",
        @"footerLegalLicenseLinkClicked",
        @"footerBrowserLinkClicked"
    ];
    for (NSString *handlerName in handlerNames) {
        [userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:handlerName];
    }

    NSString *earlyJavascriptTransforms = @""
                                           "window.webkit.messageHandlers.articleState.postMessage('indexHTMLDocumentLoaded');"
                                           "console.log = function(message){window.webkit.messageHandlers.javascriptConsoleLog.postMessage({'message': message});};";

    [userContentController addUserScript:
                               [[WKUserScript alloc] initWithSource:earlyJavascriptTransforms
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                   forMainFrameOnly:YES]];

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];

#if DEBUG || TEST
    if (self.wkUserContentControllerTestingConfigurationBlock) {
        self.wkUserContentControllerTestingConfigurationBlock(userContentController);
    }
#endif

    configuration.userContentController = userContentController;
    configuration.applicationNameForUserAgent = @"WikipediaApp";
    return configuration;
}

- (void)setWebView:(WKWebView *)webView {
    if (webView == _webView) {
        return;
    }
    _webView = webView;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.lastClickedReferencesGroup = @[];

    self.contentWidthPercentage = 1;

    self.webView = [[WMFWebView alloc] initWithFrame:CGRectZero configuration:[self configuration]];
    self.webView.allowsLinkPreview = NO;
    self.webView.scrollView.delegate = self;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

    [self addHeaderView];

    [self.containerView wmf_addSubviewWithConstraintsToEdges:self.webView];
    [self.containerView sendSubviewToBack:self.webView];

    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;

    self.zeroStatusLabel.font = [UIFont systemFontOfSize:12];
    self.zeroStatusLabel.text = @"";

    [self displayArticle];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
}

- (void)viewWillAppear:(BOOL)animated {
    self.webView.scrollView.delegate = self;
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateZeroBannerWithNotification:)
                                                 name:WMFZeroRatingChanged
                                               object:nil];
    // should happen in will appear to prevent bar from being incorrect during transitions
    [self updateZeroBanner];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refererenceLinkTappedWithNotification:)
                                                 name:WMFReferenceLinkTappedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(articleUpdatedWithNotification:)
                                                 name:WMFArticleUpdatedNotification
                                               object:nil];

    UIGestureRecognizer *interactivePopGR = self.navigationController.interactivePopGestureRecognizer;
    if (interactivePopGR) {
        [self.webView.scrollView.panGestureRecognizer requireGestureRecognizerToFail:interactivePopGR];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    self.webView.scrollView.delegate = nil;
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WMFZeroRatingChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WMFReferenceLinkTappedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WMFArticleUpdatedNotification object:nil];
}

- (void)articleUpdatedWithNotification:(NSNotification *)notification {
    if (notification.object) {
        if ([notification.object isMemberOfClass:[WMFArticle class]]) {
            WMFArticle *article = (WMFArticle *)notification.object;
            NSURL *articleURL = [NSURL URLWithString:article.key];
            if (articleURL) {
                [self updateReadMoreSaveButtonIsSavedStateForURL:articleURL];
            }
        }
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Zero

- (void)updateZeroBannerWithNotification:(NSNotification *)notification {
    [self updateZeroBanner];
}

- (void)updateZeroBanner {
    if ([[SessionSingleton sharedInstance] zeroConfigurationManager].isZeroRated) {
        [self showBannerForZeroConfiguration:[[[SessionSingleton sharedInstance] zeroConfigurationManager] zeroConfiguration]];
    } else {
        self.zeroStatusLabel.text = @"";
    }
}

- (void)showBannerForZeroConfiguration:(WMFZeroConfiguration *)zeroConfiguration {
    self.zeroStatusLabel.text = zeroConfiguration.message;
    self.zeroStatusLabel.textColor = zeroConfiguration.foreground;
    self.zeroStatusLabel.backgroundColor = zeroConfiguration.background;
}

#pragma mark - Header

- (void)addHeaderView {
    if (!self.headerView) {
        return;
    }
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webView.scrollView addSubview:self.headerView];

    NSLayoutConstraint *leadingConstraint = [self.webView.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor];
    NSLayoutConstraint *trailingConstraint = [self.webView.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor];
    [self.webView addConstraints:@[leadingConstraint, trailingConstraint]];

    NSLayoutConstraint *topConstraint = [self.webView.scrollView.topAnchor constraintEqualToAnchor:self.headerView.topAnchor];
    [self.webView.scrollView addConstraint:topConstraint];

    self.headerHeightConstraint = [self.headerView.heightAnchor constraintEqualToConstant:0];
    [self.headerView addConstraint:self.headerHeightConstraint];
}

- (void)showLicenseButtonPressed {
    [self wmf_openExternalUrl:WMFLicenses.CCBYSA3URL];
}

- (void)setHeaderView:(UIView *)headerView {
    NSAssert(!self.headerView, @"Dynamic/re-configurable header view is not supported.");
    NSAssert(!self.isViewLoaded, @"Expected header to be configured before viewDidLoad.");
    _headerView = headerView;
}

- (CGFloat)headerHeightForCurrentArticle {
    if (self.article.isMain || !self.article.imageURL || [self.article.url wmf_isNonStandardURL]) {
        return 0;
    } else {
        return WebViewControllerHeaderImageHeight;
    }
}

#pragma mark - Scrolling

- (void)scrollToFragment:(NSString *)fragment {
    [self scrollToFragment:fragment animated:YES];
}

- (void)scrollToFragment:(NSString *)fragment animated:(BOOL)animated {
    if (fragment.length == 0) {
        // No section so scroll to top. (Used when "Introduction" is selected.)
        [self.webView.scrollView scrollRectToVisible:CGRectMake(0, 1, 1, 1) animated:animated];
    } else {
        if (!animated) {
            [self.webView wmf_scrollToFragment:fragment];
            return;
        }
        [self.webView getScrollViewRectForHtmlElementWithId:fragment
                                                 completion:^(CGRect rect) {
                                                     if (!CGRectIsNull(rect)) {
                                                         [self.webView.scrollView wmf_safeSetContentOffset:CGPointMake(self.webView.scrollView.contentOffset.x, rect.origin.y)
                                                                                                  animated:animated
                                                                                                completion:^(BOOL finished){
                                                                                                }];
                                                     }
                                                 }];
    }
}

- (void)scrollToSection:(MWKSection *)section animated:(BOOL)animated {
    [self scrollToFragment:section.anchor animated:animated];
}

- (void)accessibilityCursorToSection:(MWKSection *)section {
    // This might shift the visual scroll position. To prevent it affecting other users,
    // we will only do it when we detect than an assistive technology which actually needs this is running.
    [self.webView wmf_accessibilityCursorToFragment:section.anchor];
}

- (void)getCurrentVisibleSectionCompletion:(void (^)(MWKSection *_Nullable, NSError *__nullable error))completion {
    [self.webView getIndexOfTopOnScreenElementWithPrefix:@"section_heading_and_content_block_"
                                                   count:self.article.sections.count
                                              completion:^(id obj, NSError *error) {
                                                  if (error) {
                                                      completion(nil, error);
                                                  } else {
                                                      NSInteger indexOfFirstOnscreenSection = ((NSNumber *)obj).integerValue;
                                                      completion(indexOfFirstOnscreenSection == -1 ? nil : self.article.sections[indexOfFirstOnscreenSection], error);
                                                  }
                                              }];
}

- (void)getCurrentVisibleFooterIndexCompletion:(void (^)(NSNumber *_Nullable, NSError *__nullable error))completion {
    [self.webView getIndexOfTopOnScreenElementWithPrefix:@"pagelib_footer_container_section_"
                                                   count:2
                                              completion:^(id obj, NSError *error) {
                                                  if (error) {
                                                      completion(nil, error);
                                                  } else {
                                                      NSNumber *indexOfFirstOnscreenSection = ((NSNumber *)obj);
                                                      completion(indexOfFirstOnscreenSection.integerValue == -1 ? nil : indexOfFirstOnscreenSection, error);
                                                  }
                                              }];
}

- (CGFloat)currentVerticalOffset {
    return self.webView.scrollView.contentOffset.y;
}

#pragma mark UIContainerViewControllerCallbacks

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return YES;
}

#pragma mark - Display article

- (void)setArticle:(MWKArticle *_Nullable)article articleURL:(NSURL *)articleURL {
    self.articleURL = articleURL;
    self.article = article;
}

- (void)setArticle:(MWKArticle *)article {
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

    self.headerView.alpha = self.isHeaderFadingEnabled ? 0 : 1;
    CGFloat headerHeight = [self headerHeightForCurrentArticle];
    self.headerHeightConstraint.constant = headerHeight;
    CGFloat marginWidth = [self marginWidthForSize:self.view.bounds.size];

    WMFProxyServer *proxy = [WMFProxyServer sharedProxyServer];
    [proxy cacheSectionDataForArticle:self.article];

    [self.webView loadHTML:@"" baseURL:self.article.url withAssetsFile:@"index.html" scrolledToFragment:self.articleURL.fragment padding:UIEdgeInsetsMake(headerHeight, marginWidth, 0, marginWidth) theme:self.theme];

    NSString *shareMenuItemTitle = WMFLocalizedStringWithDefaultValue(@"share-menu-item", nil, nil, @"Share…", @"Button label for 'Share…' menu");
    UIMenuItem *shareSnippet = [[UIMenuItem alloc] initWithTitle:shareMenuItemTitle
                                                          action:@selector(shareMenuItemTapped:)];
    [UIMenuController sharedMenuController].menuItems = @[shareSnippet];
}

#pragma mark References

- (void)refererenceLinkTappedWithNotification:(NSNotification *)notification {
    [self wmf_dismissReferencePopoverAnimated:NO
                                   completion:^{
                                       NSAssert([notification.object isMemberOfClass:[NSURL class]], @"WMFReferenceLinkTappedNotification did not contain NSURL");
                                       NSURL *URL = notification.object;
                                       NSAssert(URL != nil, @"WMFReferenceLinkTappedNotification NSURL was unexpectedly nil");

                                       if (URL != nil) {
                                           NSString *domain = [SessionSingleton sharedInstance].currentArticleSiteURL.wmf_language;
                                           MWLanguageInfo *languageInfo = [MWLanguageInfo languageInfoForCode:domain];
                                           NSString *baseUrl = [NSString stringWithFormat:@"https://%@.wikipedia.org/", languageInfo.code];
                                           if ([URL.absoluteString hasPrefix:[NSString stringWithFormat:@"%@%@", baseUrl, @"#"]]) {
                                               [self scrollToFragment:URL.fragment];
                                           } else if ([URL.absoluteString hasPrefix:[NSString stringWithFormat:@"%@%@", baseUrl, @"wiki/"]]) {
#pragma warning Assuming that the url is on the same language wiki - what about other wikis ?
                                               [self.delegate webViewController:self
                                                      didTapOnLinkForArticleURL:URL];
                                           } else if (
                                               [URL.scheme isEqualToString:@"http"] ||
                                               [URL.scheme isEqualToString:@"https"] ||
                                               [URL.scheme isEqualToString:@"mailto"]) {
                                               [self wmf_openExternalUrl:URL];
                                           }
                                       }
                                   }];
}

- (void)showReferenceFromLastClickedReferencesGroupAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.lastClickedReferencesGroup.count) {
        NSAssert(false, @"Expected index or reference group not found.");
        return;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self showReferencePageViewControllerWithGroup:self.lastClickedReferencesGroup selectedIndex:index];
    } else {
        [self showReferencePopoverMessageViewControllerWithGroup:self.lastClickedReferencesGroup selectedIndex:index];
    }
}

- (void)showReferencePageViewControllerWithGroup:(NSArray<WMFReference *> *)referenceGroup selectedIndex:(NSInteger)selectedIndex {
    WMFReferencePageViewController *vc = [WMFReferencePageViewController wmf_viewControllerFromReferencePanelsStoryboard];
    vc.pageViewController.delegate = self;
    vc.appearanceDelegate = self;
    [vc applyTheme:self.theme];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    vc.lastClickedReferencesIndex = selectedIndex;
    vc.lastClickedReferencesGroup = referenceGroup;
    [self presentViewController:vc
                       animated:NO
                     completion:^{
                         [self scrollTappedReferenceUpIfNecessaryWithReferencePageViewController:vc];
                     }];
}

- (void)scrollTappedReferenceUpIfNecessaryWithReferencePageViewController:(WMFReferencePageViewController *)controller {
    CGRect windowCoordsRefGroupRect = [self windowCoordsReferenceGroupRect];
    UIView *firstPanel = [controller firstPanelView];
    if (!CGRectIsEmpty(windowCoordsRefGroupRect) && firstPanel && controller.backgroundView) {
        CGRect panelRectInWindowCoords = [firstPanel convertRect:firstPanel.bounds toView:nil];
        CGRect refGroupRectInWindowCoords = [controller.backgroundView convertRect:windowCoordsRefGroupRect toView:nil];
        if (CGRectIntersectsRect(windowCoordsRefGroupRect, panelRectInWindowCoords)) {
            CGFloat refGroupScrollOffsetY = self.webView.scrollView.contentOffset.y + CGRectGetMinY(refGroupRectInWindowCoords);
            CGFloat newOffsetY = refGroupScrollOffsetY - 0.5 * CGRectGetMinY(panelRectInWindowCoords) + 0.5 * CGRectGetHeight(refGroupRectInWindowCoords) - 0.5 * self.delegate.navigationBar.visibleHeight;
            CGFloat contentInsetTop = self.webView.scrollView.contentInset.top;
            if (newOffsetY <= 0 - contentInsetTop) {
                newOffsetY = 0 - contentInsetTop;
                [self.delegate.navigationBar setNavigationBarPercentHidden:0 underBarViewPercentHidden:0 extendedViewPercentHidden:0 topSpacingPercentHidden:0 shadowAlpha:1 animated:YES additionalAnimations:NULL];
            }
            CGFloat delta = self.webView.scrollView.contentOffset.y - newOffsetY;
            CGPoint centeredOffset = CGPointMake(self.webView.scrollView.contentOffset.x, newOffsetY);
            [self.webView.scrollView wmf_safeSetContentOffset:centeredOffset
                                                     animated:YES
                                                   completion:^(BOOL finished) {
                                                       controller.backgroundView.clearRect = CGRectOffset(windowCoordsRefGroupRect, 0, delta);
                                                   }];
        } else {
            controller.backgroundView.clearRect = windowCoordsRefGroupRect;
        }
    }
}

- (CGRect)windowCoordsReferenceGroupRect {
    WMFReference *firstRef = self.lastClickedReferencesGroup.firstObject;
    if (firstRef) {
        CGRect rect = firstRef.rect;
        for (WMFReference *reference in self.lastClickedReferencesGroup) {
            rect = CGRectUnion(rect, reference.rect);
        }
        rect = [self.webView convertRect:rect toView:nil];
        rect = CGRectOffset(rect, 0, 1);
        rect = CGRectInset(rect, -1, -3);
        return rect;
    }
    return CGRectNull;
}

- (void)showReferencePopoverMessageViewControllerWithGroup:(NSArray<WMFReference *> *)referenceGroup selectedIndex:(NSInteger)selectedIndex {
    if (selectedIndex < 0 || selectedIndex >= referenceGroup.count) {
        return;
    }
    WMFReference *selectedReference = [referenceGroup objectAtIndex:selectedIndex];
    CGFloat width = MIN(MIN(self.view.frame.size.width, self.view.frame.size.height) - 20, 355);
    [self wmf_presentReferencePopoverViewControllerForReference:selectedReference
                                                          width:width];
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<WMFReferencePanelViewController *> *)pendingViewControllers {
    for (WMFReferencePanelViewController *panel in pageViewController.viewControllers) {
        [self.webView wmf_unHighlightLinkID:panel.reference.refId];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController
         didFinishAnimating:(BOOL)finished
    previousViewControllers:(NSArray<WMFReferencePanelViewController *> *)previousViewControllers
        transitionCompleted:(BOOL)completed {

    WMFReferencePanelViewController *firstRefVC = pageViewController.viewControllers.firstObject;
    [self.webView wmf_highlightLinkID:firstRefVC.reference.refId];
}

- (void)referencePageViewControllerWillAppear:(WMFReferencePageViewController *)referencePageViewController {
    WMFReferencePanelViewController *firstRefVC = referencePageViewController.pageViewController.viewControllers.firstObject;
    [self.webView wmf_highlightLinkID:firstRefVC.reference.refId];
}

- (void)referencePageViewControllerWillDisappear:(WMFReferencePageViewController *)referencePageViewController {
    for (WMFReferencePanelViewController *panel in referencePageViewController.pageViewController.viewControllers) {
        [self.webView wmf_unHighlightLinkID:panel.reference.refId];
    }
}

#pragma mark - Share Actions

- (void)shareMenuItemTapped:(id)sender {
    [self.webView wmf_getSelectedText:^(NSString *_Nonnull text) {
        [self shareSnippet:text];
    }];
}

#pragma mark - Sharing

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if ([[self findInPageKeyboardBar] isVisible]) {
        return NO;
    }

    if (action == @selector(shareSnippet:)) {
        [self.webView wmf_getSelectedText:^(NSString *_Nonnull text) {
            [self.delegate webViewController:self didSelectText:text];
        }];
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)shareSnippet:(NSString *)snippet {
    [self.delegate webViewController:self didTapShareWithSelectedText:snippet];
}

- (void)editHistoryButtonPushed {
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:[PageHistoryViewController wmf_initialViewControllerFromClassStoryboard]];
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)setFontSizeMultiplier:(NSNumber *)fontSize {
    if (fontSize == nil) {
        fontSize = @(100);
    }
    if ([_fontSizeMultiplier isEqual:fontSize]) {
        return;
    }
    _fontSizeMultiplier = fontSize;
    [self.webView wmf_setTextSize:fontSize.integerValue];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(webViewController:scrollViewDidScroll:)]) {
        [self.delegate webViewController:self scrollViewDidScroll:scrollView];
    }
    [self minimizeFindInPage];
    if (@available(iOS 12.0, *)) {
        // Somewhere along the line the webView.scrollView.contentOffset is set to 0,0 on iOS 12 and there's nothing useful in the stack trace
        // Workaround this issue by correcting it to the top offset if it occurs before the first user scroll event
        // 😂😭
        if (!self.isAfterFirstUserScrollInteraction && CGPointEqualToPoint(scrollView.contentOffset, CGPointZero)) {
            [scrollView wmf_scrollToTop:NO];
        }
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(webViewController:scrollViewShouldScrollToTop:)]) {
        return [self.delegate webViewController:self scrollViewShouldScrollToTop:scrollView];
    }
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(webViewController:scrollViewDidScrollToTop:)]) {
        [self.delegate webViewController:self scrollViewDidScrollToTop:scrollView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.afterFirstUserScrollInteraction = YES;
    if ([self.delegate respondsToSelector:@selector(webViewController:scrollViewWillBeginDragging:)]) {
        [self.delegate webViewController:self scrollViewWillBeginDragging:scrollView];
    }
    [self wmf_dismissReferencePopoverAnimated:NO completion:nil];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocityPoint targetContentOffset:(inout CGPoint *)targetContentOffset {
    if ([self.delegate respondsToSelector:@selector(webViewController:scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [self.delegate webViewController:self scrollViewWillEndDragging:scrollView withVelocity:velocityPoint targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(webViewController:scrollViewDidEndDecelerating:)]) {
        [self.delegate webViewController:self scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(webViewController:scrollViewDidEndScrollingAnimation:)]) {
        [self.delegate webViewController:self scrollViewDidEndScrollingAnimation:scrollView];
    }
}

#pragma mark -

- (void)setContentWidthPercentage:(CGFloat)contentWidthPercentage {
    if (_contentWidthPercentage != contentWidthPercentage) {
        _contentWidthPercentage = contentWidthPercentage;
        [self updateWebContentMarginForSize:self.view.bounds.size force:NO];
    }
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    if (self.viewIfLoaded == nil) {
        return;
    }

    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.scrollView.backgroundColor = [UIColor clearColor];
    self.webView.scrollView.indicatorStyle = theme.scrollIndicatorStyle;
    self.containerView.backgroundColor = theme.colors.paperBackground;
    self.view.backgroundColor = theme.colors.paperBackground;
    self.statusBarUnderlayView.backgroundColor = theme.colors.chromeBackground;
    [self.statusBarUnderlayView wmf_addBottomShadowWith:theme];
    [self.webView wmf_applyTheme:theme];
    [_inputAccessoryView applyTheme:theme];
}

@end
