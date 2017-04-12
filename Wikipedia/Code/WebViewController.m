#import "WebViewController_Private.h"

#import "Wikipedia-Swift.h"

@import WebKit;
#import <Masonry/Masonry.h>
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

#import "WMFZeroConfiguration.h"
#import "WKWebView+LoadAssetsHtml.h"
#import "WKWebView+WMFWebViewControllerJavascript.h"
#import "NSURL+WMFProxyServer.h"
#import "WMFImageTag.h"
#import "WKScriptMessage+WMFScriptMessage.h"
#import "WMFFindInPageKeyboardBar.h"
#import "UIView+WMFDefaultNib.h"
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

NSString *const WMFCCBySALicenseURL =
    @"https://creativecommons.org/licenses/by-sa/3.0/";

static const NSString *kvo_WebViewController_webView_scrollView = nil;
static const NSString *kvo_WebViewController_webViewScrollView_contentSize = nil;
static const NSString *kvo_WebViewController_footerContainerView_bounds = nil;

@interface WebViewController () <WKScriptMessageHandler, UIScrollViewDelegate, WMFFindInPageKeyboardBarDelegate, UIPageViewControllerDelegate, WMFReferencePageViewAppearanceDelegate>

@property (nonatomic, strong) MASConstraint *headerHeight;
@property (nonatomic, strong, nullable) UIView *footerContainerView;
@property (nonatomic, strong) NSMutableDictionary *footerViewHeadersByIndex;
@property (nonatomic, strong) WMFArticleFooterView *footerLicenseView;
@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) NSNumber *fontSizeMultiplier;

@property (strong, nonatomic) MASConstraint *footerContainerViewTopConstraint;
@property (strong, nonatomic) MASConstraint *footerContainerViewLeftMarginConstraint;
@property (strong, nonatomic) MASConstraint *footerContainerViewRightMarginConstraint;

@property (nonatomic) CGFloat marginWidth;

@property (nonatomic, strong) NSArray *findInPageMatches;
@property (nonatomic) NSInteger findInPageSelectedMatchIndex;
@property (nonatomic) BOOL disableMinimizeFindInPage;
@property (nonatomic, readwrite, retain) WMFFindInPageKeyboardBar *inputAccessoryView;

@property (nonatomic, strong) NSArray<WMFReference *> *lastClickedReferencesGroup;

@end

@implementation WebViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //explicitly nil these values out to remove KVO observers
    self.webViewScrollView = nil;
    self.webView = nil;
    self.footerContainerView = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.session = [SessionSingleton sharedInstance];
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
    }
    return self;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {

    WMFWKScriptMessageType messageType = [WKScriptMessage wmf_typeForMessageName:message.name];
    id safeMessageBody = [message wmf_safeMessageBodyForType:messageType];

    switch (messageType) {
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

- (void)handleMessageConsoleScriptMessage:(NSDictionary *)messageDict {
    DDLogDebug(@"\n\nMessage from Javascript console:\n\t%@\n\n", messageDict[@"message"]);
}

- (void)handleClickLinkScriptMessage:(NSDictionary *)messageDict {
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
                                               NSURL *url = [NSURL URLWithString:href];
                                               if (!url.wmf_domain) {
                                                   url = [NSURL wmf_URLWithSiteURL:self.article.url escapedDenormalizedInternalLink:href];
                                               }
                                               url = [url wmf_urlByPrependingSchemeIfSchemeless];
                                               [(self).delegate webViewController:(self)didTapOnLinkForArticleURL:url];
                                           } else {
                                               // A standard external link, either explicitly http(s) or left protocol-relative on web meaning http(s)
                                               if ([href hasPrefix:@"#"]) {
                                                   [self scrollToFragment:[href substringFromIndex:1]];
                                               } else {
                                                   if ([href hasPrefix:@"//"]) {
                                                       // Expand protocol-relative link to https -- secure by default!
                                                       href = [@"https:" stringByAppendingString:href];
                                                   }
                                                   NSURL *url = [NSURL URLWithString:href];
                                                   NSCAssert(url, @"Failed to from URL from link %@", href);
                                                   if (url) {
                                                       [self wmf_openExternalUrl:url];
                                                   }
                                               }
                                           }
                                       }];
                                   }];
}

- (void)handleClickImageScriptMessage:(NSDictionary *)messageDict {
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

- (void)handleClickReferenceScriptMessage:(NSDictionary *)messageDict {
    NSAssert(messageDict[@"referencesGroup"], @"Expected key 'referencesGroup' not found in script message dictionary");
    self.lastClickedReferencesGroup = [messageDict[@"referencesGroup"] wmf_map:^id(NSDictionary *referenceDict) {
        return [[WMFReference alloc] initWithScriptMessageDict:referenceDict];
    }];

    NSAssert(messageDict[@"selectedIndex"], @"Expected key 'selectedIndex' not found in script message dictionary");
    NSNumber *selectedIndex = messageDict[@"selectedIndex"];
    [self showReferenceFromLastClickedReferencesGroupAtIndex:selectedIndex.integerValue];
}

- (void)handleClickEditScriptMessage:(NSDictionary *)messageDict {
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

- (void)handleNonAnchorTouchEndedWithoutDraggingScriptMessage {
    [self wmf_dismissReferencePopoverAnimated:NO
                                   completion:^{
                                       [self hideFindInPageWithCompletion:nil];
                                   }];
}

- (void)handleLateJavascriptTransformScriptMessage:(NSString *)messageString {
    if ([messageString isEqualToString:@"collapseTables"]) {
        [self.webView wmf_collapseTablesForArticle:self.article];
    } else if ([messageString isEqualToString:@"setLanguage"]) {
        [self.webView wmf_setLanguage:[MWLanguageInfo languageInfoForCode:self.article.url.wmf_language]];
    } else if ([messageString isEqualToString:@"setPageProtected"] && !self.article.editable) {
        [self.webView wmf_setPageProtected];
    } else if ([messageString isEqualToString:@"addReadMoreFooter"]) {
        [self.webView wmf_addReadMoreFooterForArticle:self.article];
    }
}

- (void)handleArticleStateScriptMessage:(NSString *)messageString {
    if ([messageString isEqualToString:@"articleLoaded"]) {
        [self updateWebContentMarginForSize:self.view.bounds.size];
        NSAssert(self.article, @"Article not set - may need to use the old 0.1 second delay...");
        [self.delegate webViewController:self didLoadArticle:self.article];

        [UIView animateWithDuration:0.3
                              delay:0.5f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.headerView.alpha = 1.f;
                             self.footerContainerView.alpha = 1.f;
                         }
                         completion:^(BOOL done){
                         }];
        [self forceUpdateWebviewPaddingForFooters];
    }
}

- (void)handleFindInPageMatchesFoundMessage:(NSArray *)messageArray {
    self.findInPageMatches = messageArray;
    self.findInPageSelectedMatchIndex = -1;
}

#pragma mark - Find-in-page

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (WMFFindInPageKeyboardBar *)inputAccessoryView {
    if (!_inputAccessoryView) {
        _inputAccessoryView = [WMFFindInPageKeyboardBar wmf_viewFromClassNib];
        _inputAccessoryView.delegate = self;
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

- (CGFloat)marginWidthForSize:(CGSize)size {
    return floor(0.5 * size.width * (1 - self.contentWidthPercentage));
}

- (void)updateFooterMarginForSize:(CGSize)size {
    CGFloat marginWidth = [self marginWidthForSize:size];
    self.footerContainerViewLeftMarginConstraint.offset = marginWidth;
    self.footerContainerViewRightMarginConstraint.offset = 0 - marginWidth;

    BOOL hasMargins = marginWidth > 0;
    self.footerContainerView.backgroundColor = hasMargins ? [UIColor whiteColor] : [UIColor wmf_articleBackground];
}

- (void)updateWebContentMarginForSize:(CGSize)size {
    CGFloat newMarginWidth = [self marginWidthForSize:self.view.bounds.size];
    if (ABS(self.marginWidth - newMarginWidth) >= 0.5) {
        self.marginWidth = newMarginWidth;
        NSString *jsFormat = @"document.body.style.paddingLeft='%ipx';document.body.style.paddingRight='%ipx';";
        CGFloat marginWidth = [self marginWidthForSize:size];
        int padding = (int)MAX(0, marginWidth);
        NSString *js = [NSString stringWithFormat:jsFormat, padding, padding];
        [self.webView evaluateJavaScript:js completionHandler:NULL];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateWebContentMarginForSize:self.view.bounds.size];
    [self updateFooterMarginForSize:self.view.bounds.size];
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
    if (self.findInPageMatches.count == 0) {
        return;
    }
    NSString *matchSpanId = [self.findInPageMatches wmf_safeObjectAtIndex:self.findInPageSelectedMatchIndex];
    if (matchSpanId == nil) {
        return;
    }
    @weakify(self);
    [self.webView getScrollViewRectForHtmlElementWithId:matchSpanId
                                             completion:^(CGRect rect) {
                                                 @strongify(self);
                                                 self.disableMinimizeFindInPage = YES;
                                                 [self.webView.scrollView wmf_safeSetContentOffset:CGPointMake(self.webView.scrollView.contentOffset.x, fmaxf(rect.origin.y - 80.f, 0.f))
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
    term = [term stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
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

    [userContentController addUserScript:[[WKUserScript alloc] initWithSource:@"window.webkit.messageHandlers.lateJavascriptTransform.postMessage('collapseTables');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES]];

    [userContentController addUserScript:[[WKUserScript alloc] initWithSource:@"window.webkit.messageHandlers.lateJavascriptTransform.postMessage('setPageProtected');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES]];

    [userContentController addUserScript:[[WKUserScript alloc] initWithSource:@"window.webkit.messageHandlers.lateJavascriptTransform.postMessage('setLanguage');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES]];

    [userContentController addUserScript:[[WKUserScript alloc] initWithSource:@"window.webkit.messageHandlers.lateJavascriptTransform.postMessage('addReadMoreFooter');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES]];
    
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

    NSString *earlyJavascriptTransforms = @""
                                           "window.wmf.transformer.transform( 'hideRedlinks', document );"
                                           "window.wmf.transformer.transform( 'disableFilePageEdit', document );"
                                           "window.wmf.transformer.transform( 'widenImages', document );"
                                           "window.wmf.transformer.transform( 'moveFirstGoodParagraphUp', document );"
                                           "window.webkit.messageHandlers.articleState.postMessage('articleLoaded');"
                                           "console.log = function(message){window.webkit.messageHandlers.sendJavascriptConsoleLogMessageToXcodeConsole.postMessage({'message': message});};";

    [userContentController addUserScript:
                               [[WKUserScript alloc] initWithSource:earlyJavascriptTransforms
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                   forMainFrameOnly:YES]];

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
    configuration.applicationNameForUserAgent = @"WikipediaApp";
    return configuration;
}

- (void)setWebView:(WKWebView *)webView {
    if (webView == _webView) {
        return;
    }
    if (_webView) {
        [_webView removeObserver:self forKeyPath:@"scrollView"];
    }
    _webView = webView;
    if (_webView) {
        [_webView addObserver:self forKeyPath:@"scrollView" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&kvo_WebViewController_webView_scrollView];
    }
}

- (void)setWebViewScrollView:(UIScrollView *)webViewScrollView {
    if (webViewScrollView == _webViewScrollView) {
        return;
    }
    if (_webViewScrollView) {
        [_webViewScrollView removeObserver:self forKeyPath:@"contentSize"];
    }
    _webViewScrollView = webViewScrollView;
    if (_webViewScrollView) {
        [_webViewScrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&kvo_WebViewController_webViewScrollView_contentSize];
    }
}

- (void)setFooterContainerView:(UIView *)footerContainerView {
    if (footerContainerView == _footerContainerView) {
        return;
    }
    if (_footerContainerView) {
        [_footerContainerView removeObserver:self forKeyPath:@"bounds"];
    }
    _footerContainerView = footerContainerView;
    if (_footerContainerView) {
        [_footerContainerView addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&kvo_WebViewController_footerContainerView_bounds];
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.lastClickedReferencesGroup = @[];

    self.contentWidthPercentage = 1;

    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[self configuration]];
    self.webView.allowsLinkPreview = NO;
    self.webView.scrollView.delegate = self;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addFooterContainerView];
    [self addHeaderView];
    [self addFooterView];

    [self.containerView insertSubview:self.webView atIndex:0];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuide);
        make.bottom.equalTo(self.mas_bottomLayoutGuide);
        make.leading.and.trailing.equalTo(self.containerView);
    }];

    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    self.webView.scrollView.backgroundColor = [UIColor wmf_articleBackground];

    self.zeroStatusLabel.font = [UIFont systemFontOfSize:12];
    self.zeroStatusLabel.text = @"";

    self.webView.backgroundColor = [UIColor whiteColor];

    self.view.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];

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
                                             selector:@selector(updateZeroBannerWithNotification:)
                                                 name:WMFZeroRatingChanged
                                               object:nil];
    // should happen in will appear to prevent bar from being incorrect during transitions
    [self updateZeroBanner];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refererenceLinkTappedWithNotification:)
                                                 name:WMFReferenceLinkTappedNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.webView.scrollView.delegate = nil;
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WMFZeroRatingChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WMFReferenceLinkTappedNotification object:nil];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
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
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    [self wmf_dismissReferencePopoverAnimated:NO completion:nil];
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

#pragma mark - Headers & Footers

- (nullable UIView *)footerAtIndex:(NSInteger)index {
    UIView *footerView = (UIView *)[[self.footerViewControllers wmf_safeObjectAtIndex:index] view];
    UIView *footerViewHeader = self.footerViewHeadersByIndex[@(index)];
    return footerViewHeader ?: footerView;
}

- (void)scrollToFooterAtIndex:(NSInteger)index animated:(BOOL)animated {
    UIView *viewToScrollTo = [self footerAtIndex:index];
    if (viewToScrollTo) {
        CGPoint footerViewOrigin = [self.webView.scrollView convertPoint:viewToScrollTo.frame.origin
                                                                fromView:self.footerContainerView];
        footerViewOrigin.y -= self.webView.scrollView.contentInset.top;
        [self.webView.scrollView setContentOffset:footerViewOrigin animated:animated];
    }
}

- (void)accessibilityCursorToFooterAtIndex:(NSInteger)index {
    UIView *viewToScrollTo = [self footerAtIndex:index];
    if (viewToScrollTo) {
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, viewToScrollTo);
    }
}

- (NSInteger)visibleFooterIndex {
    CGRect const scrollViewContentFrame = self.webView.scrollView.wmf_contentFrame;
    if (!CGRectIntersectsRect(scrollViewContentFrame, self.footerContainerView.frame)) {
        return NSNotFound;
    }

    return [self.footerViewControllers indexOfObjectPassingTest:^BOOL(UIViewController *_Nonnull vc, NSUInteger idx, BOOL *_Nonnull stop) {
        CGRect absoluteFooterViewFrame = [self.webView.scrollView convertRect:vc.view.frame
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
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        // lead/trail must be constained to webview, the scrollview doesn't define a width
        make.leading.and.trailing.equalTo(self.webView);
        make.top.equalTo(self.webView.scrollView);
        self.headerHeight = make.height.equalTo(@(0));
    }];
}

- (WMFArticleFooterView *)footerLicenseView {
    if (!_footerLicenseView) {
        _footerLicenseView = [WMFArticleFooterView wmf_viewFromClassNib];
        [_footerLicenseView.showLicenseButton addTarget:self action:@selector(showLicenseButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _footerLicenseView;
}

- (void)showLicenseButtonPressed {
    [self wmf_openExternalUrl:[NSURL URLWithString:WMFCCBySALicenseURL]];
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
    self.footerContainerView = [UIView new];
    self.footerContainerView.backgroundColor = [UIColor wmf_articleBackground];
    self.footerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webView.scrollView addSubview:self.footerContainerView];
    [self.footerContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        // lead/trail must be constained to webview, the scrollview doesn't define a width
        self.footerContainerViewLeftMarginConstraint = make.leading.equalTo(self.webView);
        self.footerContainerViewRightMarginConstraint = make.trailing.equalTo(self.webView);
        [self updateFooterMarginForSize:self.view.bounds.size];
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
    MASViewAttribute *lastAnchor = [self.footerViewControllers wmf_reduce:self.footerContainerView.mas_top
                                                                withBlock:^MASViewAttribute *(MASViewAttribute *topAnchor,
                                                                                              UIViewController *childVC) {
                                                                    NSString *footerTitle = [self.delegate webViewController:self titleForFooterViewController:childVC];
                                                                    if (footerTitle) {
                                                                        WMFArticleFooterViewHeader *header = [WMFArticleFooterViewHeader wmf_viewFromClassNib];
                                                                        self.footerViewHeadersByIndex[@([self.footerViewControllers indexOfObject:childVC])] = header;
                                                                        header.headerLabel.text = footerTitle;
                                                                        header.translatesAutoresizingMaskIntoConstraints = NO;
                                                                        [self.footerContainerView addSubview:header];
                                                                        [header mas_remakeConstraints:^(MASConstraintMaker *make) {
                                                                            make.leading.and.trailing.equalTo(self.footerContainerView);
                                                                            make.top.equalTo(topAnchor);
                                                                        }];
                                                                        topAnchor = header.mas_bottom;
                                                                    }

                                                                    childVC.view.translatesAutoresizingMaskIntoConstraints = NO;
                                                                    [self.footerContainerView addSubview:childVC.view];
                                                                    [self updateFooterMarginForSize:self.view.bounds.size];
                                                                    [childVC.view mas_remakeConstraints:^(MASConstraintMaker *make) {
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
    [self.footerLicenseView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastAnchor);
        make.leading.and.trailing.equalTo(self.footerContainerView);
        make.bottom.equalTo(self.footerContainerView);
    }];
}

- (void)setFooterViewControllers:(NSArray<UIViewController *> *)footerViewControllers {
    if (WMF_EQUAL(self.footerViewControllers, isEqualToArray:, footerViewControllers)) {
        return;
    }
    for (UIViewController *childVC in _footerViewControllers) {
        [childVC willMoveToParentViewController:nil];
        [childVC.view removeFromSuperview];
        [childVC removeFromParentViewController];
    }
    _footerViewControllers = [footerViewControllers copy];
    for (UIViewController *childVC in _footerViewControllers) {
        [self addChildViewController:childVC];
        // didMoveToParent is called when they are added to the view
    }
    [self addFooterView];
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
        return 210;
    }
}

- (void)forceUpdateWebviewPaddingForFooters {
    self.footerContainerView.bounds = self.footerContainerView.bounds;
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
                                                                                                completion:nil];
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

- (CGFloat)currentVerticalOffset {
    return self.webView.scrollView.contentOffset.y;
}

#pragma mark UIContainerViewControllerCallbacks

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return YES;
}

- (BOOL)shouldAutomaticallyForwardRotationMethods {
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

    self.headerView.alpha = 0.f;
    self.footerContainerView.alpha = 0.f;
    CGFloat headerHeight = [self headerHeightForCurrentArticle];
    [self.headerHeight setOffset:headerHeight];
    CGFloat marginWidth = [self marginWidthForSize:self.view.bounds.size];
    [self.webView loadHTML:[self.article articleHTML] baseURL:self.article.url withAssetsFile:@"index.html" scrolledToFragment:self.articleURL.fragment padding:UIEdgeInsetsMake(headerHeight, marginWidth, 0, marginWidth)];

    UIMenuItem *shareSnippet = [[UIMenuItem alloc] initWithTitle:MWLocalizedString(@"share-a-fact-share-menu-item", nil)
                                                          action:@selector(shareMenuItemTapped:)];
    [UIMenuController sharedMenuController].menuItems = @[shareSnippet];

    [self.footerLicenseView setLicenseTextForURL:self.article.url];
}

#pragma mark Bottom menu bar

- (void)showProtectedDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:MWLocalizedString(@"page-protected-can-not-edit-title", nil) message:MWLocalizedString(@"page-protected-can-not-edit", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"button-ok", nil) style:UIAlertActionStyleCancel handler:NULL]];
    [self presentViewController:alert animated:YES completion:NULL];
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
    if (index < 0 || self.lastClickedReferencesGroup.count == 0 || [self.lastClickedReferencesGroup wmf_safeObjectAtIndex:index] == nil) {
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
    vc.delegate = self;
    vc.appearanceDelegate = self;
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
        CGRect panelRectInWebViewCoords = [firstPanel convertRect:firstPanel.bounds toView:self.webView];
        CGRect refGroupRectInWebViewCoords = [controller.backgroundView convertRect:windowCoordsRefGroupRect toView:self.webView];

        if (CGRectIntersectsRect(windowCoordsRefGroupRect, panelRectInWindowCoords)) {
            CGFloat distanceFromVerticalCenterAbovePanel = (panelRectInWebViewCoords.origin.y / 2.0) - refGroupRectInWebViewCoords.origin.y - (windowCoordsRefGroupRect.size.height / 2.0);
            CGPoint centeredOffset = CGPointMake(
                self.webView.scrollView.contentOffset.x,
                self.webView.scrollView.contentOffset.y - distanceFromVerticalCenterAbovePanel);
            [self.webView.scrollView wmf_safeSetContentOffset:centeredOffset
                                                     animated:YES
                                                   completion:^(BOOL finished) {
                                                       controller.backgroundView.clearRect = CGRectOffset(windowCoordsRefGroupRect, 0, distanceFromVerticalCenterAbovePanel);
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
    WMFReference *selectedReference = [referenceGroup wmf_safeObjectAtIndex:selectedIndex];
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
    WMFReferencePanelViewController *firstRefVC = referencePageViewController.viewControllers.firstObject;
    [self.webView wmf_highlightLinkID:firstRefVC.reference.refId];
}

- (void)referencePageViewControllerWillDisappear:(WMFReferencePageViewController *)referencePageViewController {
    for (WMFReferencePanelViewController *panel in referencePageViewController.viewControllers) {
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
    [self.webView wmf_suppressSelection];
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
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(webViewController:scrollViewDidScrollToTop:)]) {
        [self.delegate webViewController:self scrollViewDidScrollToTop:scrollView];
    }
}

#pragma mark -

- (void)setContentWidthPercentage:(CGFloat)contentWidthPercentage {
    if (_contentWidthPercentage != contentWidthPercentage) {
        _contentWidthPercentage = contentWidthPercentage;
        [self updateWebContentMarginForSize:self.view.bounds.size];
        [self updateFooterMarginForSize:self.view.bounds.size];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if (context == &kvo_WebViewController_webView_scrollView) {
        self.webViewScrollView = self.webView.scrollView;
    } else if (context == &kvo_WebViewController_webViewScrollView_contentSize) {
        [self setTopOfFooterContainerViewForContentSize:self.webViewScrollView.contentSize];
    } else if (context == &kvo_WebViewController_footerContainerView_bounds) {
        [self.webView wmf_setBottomPadding:(NSInteger)(ceil(self.footerContainerView.bounds.size.height))];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
