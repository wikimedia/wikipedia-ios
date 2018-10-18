#import "WMFArticleViewController_Private.h"
#import "Wikipedia-Swift.h"
@import WMF;

#import "WMFEmptyView.h"

// Controller
#import "UIViewController+WMFStoryboardUtilities.h"
#import "SectionEditorViewController.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFLanguagesViewController.h"
#import "PageHistoryViewController.h"
//Funnel
#import "WMFShareFunnel.h"
#import "ProtectedEditAttemptFunnel.h"

// Networking
#import "WMFArticleFetcher.h"

// View
#import <FLAnimatedImage/FLAnimatedImageView.h>
#import "UIViewController+WMFEmptyView.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "WMFArticleTextActivitySource.h"
#import "UIImageView+WMFFaceDetectionBasedOnUIApplicationSharedApplication.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"

#if WMF_TWEAKS_ENABLED
#import <Tweaks/FBTweakInline.h>
#endif
#import "WKWebView+WMFWebViewControllerJavascript.h"
#import "WMFImageInfoController.h"
#import "UIViewController+WMFDynamicHeightPopoverMessage.h"

#import "Wikipedia-Swift.h"

@import SafariServices;

NS_ASSUME_NONNULL_BEGIN

static const CGFloat WMFArticleViewControllerExpandedTableOfContentsWidthPercentage = 0.33;
static const CGFloat WMFArticleViewControllerTableOfContentsSeparatorWidth = 1;
static const CGFloat WMFArticleViewControllerTableOfContentsSectionUpdateScrollDistance = 15;

@interface MWKArticle (WMFSharingActivityViewController)

- (nullable UIActivityViewController *)sharingActivityViewControllerWithTextSnippet:(nullable NSString *)text
                                                                         fromButton:(UIBarButtonItem *)button
                                                                        shareFunnel:(nullable WMFShareFunnel *)shareFunnel
                                                                     customActivity:(nullable UIActivity *)customActivity;
@end

@implementation MWKArticle (WMFSharingActivityViewController)

- (nullable UIActivityViewController *)sharingActivityViewControllerWithTextSnippet:(nullable NSString *)text
                                                                         fromButton:(UIBarButtonItem *)button
                                                                        shareFunnel:(nullable WMFShareFunnel *)shareFunnel
                                                                     customActivity:(nullable UIActivity *)customActivity {
    NSParameterAssert(button);
    if (!button) {
        //If we get no button, we will crash below on iPad
        //The assert above should help, but lets make sure we bail in prod
        NSAssert(false, @"Should have a button by now...");
        return nil;
    }
    [shareFunnel logShareButtonTappedResultingInSelection:text];

    WMFShareActivityController *vc = nil;
    if (customActivity) {
        vc = [[WMFShareActivityController alloc] initWithCustomActivity:customActivity article:self textActivitySource:[[WMFArticleTextActivitySource alloc] initWithArticle:self shareText:text]];
    } else {
        vc = [[WMFShareActivityController alloc] initWithArticle:self textActivitySource:[[WMFArticleTextActivitySource alloc] initWithArticle:self shareText:text]];
    }

    UIPopoverPresentationController *presenter = [vc popoverPresentationController];
    presenter.barButtonItem = button;
    return vc;
}

@end

@interface WMFArticleViewController () <SectionEditorViewControllerDelegate,
                                        UIViewControllerPreviewingDelegate,
                                        WMFLanguagesViewControllerDelegate,
                                        WMFReadingThemesControlsViewControllerDelegate,
                                        UIPopoverPresentationControllerDelegate,
                                        WKUIDelegate,
                                        WMFArticlePreviewingActionsDelegate,
                                        ReadingListsAlertControllerDelegate,
                                        WMFReadingListHintPresenter,
                                        EventLoggingEventValuesProviding,
                                        WMFSearchButtonProviding,
                                        WMFImageScaleTransitionProviding,
                                        UIGestureRecognizerDelegate,
                                        EventLoggingSearchSourceProviding,
                                        DescriptionEditViewControllerDelegate>

// Data
@property (nonatomic, strong, readwrite, nullable) MWKArticle *article;

// Children
@property (nonatomic, strong, nullable) WMFTableOfContentsViewController *tableOfContentsViewController;
@property (nonatomic, strong) WebViewController *webViewController;

@property (nonatomic, strong) WMFReadingThemesControlsViewController *readingThemesViewController;
@property (nonatomic, strong) UIPopoverPresentationController *readingThemesPopoverPresenter;

@property (nonatomic, strong, readwrite) NSURL *articleURL;
@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;

@property (nonatomic, strong) SavedPagesFunnel *savedPagesFunnel;
@property (strong, nonatomic, nullable, readwrite) WMFShareFunnel *shareFunnel;

// Data
@property (nonatomic, strong, readonly) MWKHistoryEntry *historyEntry;
@property (nonatomic, strong, readonly) MWKSavedPageList *savedPages;
@property (nonatomic, strong, readonly) MWKHistoryList *recentPages;

// Fetchers
@property (nonatomic, strong) WMFArticleFetcher *articleFetcher;
@property (nonatomic, strong, nullable) NSURLSessionTask *articleFetcherPromise;
@property (nonatomic, strong, nullable) WMFReachabilityNotifier *reachabilityNotifier;

// Views
@property (nonatomic, strong, nullable) UIImageView *headerImageTransitionView;
@property (nonatomic, strong) UIImageView *headerImageView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong, readwrite) UIBarButtonItem *saveToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *languagesToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *shareToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *readingThemesControlsToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *showTableOfContentsToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *hideTableOfContentsToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *findInPageToolbarItem;
@property (nonatomic, strong) UIRefreshControl *pullToRefresh;
@property (nonatomic, readwrite, nullable) UIImageView *imageScaleTransitionView;

// Table of Contents
@property (nonatomic, strong) UISwipeGestureRecognizer *tableOfContentsCloseGestureRecognizer;
@property (nonatomic, strong) UIView *tableOfContentsSeparatorView;
@property (nonatomic) CGFloat previousContentOffsetYForTOCUpdate;

// Previewing
@property (nonatomic, weak) id<UIViewControllerPreviewing> leadImagePreviewingContext;

@property (strong, nonatomic, nullable) NSTimer *significantlyViewedTimer;

/**
 *  We need to do this to prevent auto loading from occuring,
 *  if we do something to the article like edit it and force a reload
 */
@property (nonatomic, assign) BOOL skipFetchOnViewDidAppear;

@property (assign, getter=shouldShareArticleOnLoad) BOOL shareArticleOnLoad;

@property (nonatomic, strong, readwrite) WMFReadingListHintController *readingListHintController;

@property (nonatomic, readwrite) EventLoggingCategory eventLoggingCategory;
@property (nonatomic, readwrite) EventLoggingLabel eventLoggingLabel;

@end

@implementation WMFArticleViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithArticleURL:(NSURL *)url
                         dataStore:(MWKDataStore *)dataStore
                             theme:(WMFTheme *)theme {

    NSParameterAssert(url.wmf_title);
    NSParameterAssert(dataStore);

    self = [super init];
    if (self) {
        self.theme = theme;
        self.addingArticleToHistoryListEnabled = YES;
        self.savingOpenArticleTitleEnabled = YES;
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.query = nil;
        self.articleURL = components.URL;
        self.dataStore = dataStore;
        self.readingListHintController = [[WMFReadingListHintController alloc] initWithDataStore:dataStore presenter:self];

        self.hidesBottomBarWhenPushed = YES;
        self.edgesForExtendedLayout = UIRectEdgeAll;
        self.extendedLayoutIncludesOpaqueBars = YES;
        @weakify(self);
        self.reachabilityNotifier = [[WMFReachabilityNotifier alloc] initWithHost:WMFDefaultSiteDomain callback:^(BOOL isReachable, SCNetworkReachabilityFlags flags) {
            if (isReachable) {
                @strongify(self);
                [self.reachabilityNotifier stop];
                @weakify(self);
                dispatch_async(dispatch_get_main_queue(), ^{
                    @strongify(self);
                    [self fetchArticleIfNeeded];
                });
            }
        }];
        self.savingOpenArticleTitleEnabled = YES;
        self.addingArticleToHistoryListEnabled = YES;
        self.peekingAllowed = YES;
    }
    return self;
}

#pragma mark - Accessors

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.articleURL];
}

- (void)setArticle:(nullable MWKArticle *)article {
    NSAssert(self.isViewLoaded, @"Expecting article to only be set after the view loads.");
    if (![article.url isEqual:[self.articleURL wmf_URLWithFragment:nil]]) {
        self.articleURL = article.url;
    }

    _shareFunnel = nil;
    NSURL *articleURLToCancel = self.articleURL;
    if (articleURLToCancel && ![article.url isEqual:articleURLToCancel]) {
        [self.articleFetcher cancelFetchForArticleURL:articleURLToCancel];
    }

    _article = article;

    // always update webVC & headerGallery, even if nil so they are reset if needed
    [self.webViewController setArticle:_article articleURL:self.articleURL];

    if (self.article) {
        self.headerImageView.backgroundColor = self.theme.colors.paperBackground;
        if ([self.article.url wmf_isNonStandardURL]) {
            self.headerImageView.image = nil;
        } else {
            [self.headerImageView wmf_setImageWithMetadata:_article.leadImage
                                               detectFaces:YES
                                                   failure:WMFIgnoreErrorHandler
                                                   success:^{
                                                       [self layoutHeaderImageViewForSize:self.view.bounds.size];
                                                   }];
            NSURL *articleURL = self.articleURL;
            if (articleURL && self.isAddingArticleToHistoryListEnabled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.dataStore.historyList addPageToHistoryWithURL:articleURL];
                });
            }
        }
        [self startSignificantlyViewedTimer];
        [self wmf_hideEmptyView];
        [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_articleViewActivityWithArticle:self.article]];
    }

    [self updateToolbar];
    [self setupTableOfContentsViewController];
    [self setupReadingThemesControls];
    [self updateTableOfContentsForFootersIfNeeded];

    if (_article && self.shouldShareArticleOnLoad) {
        self.shareArticleOnLoad = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self shareArticle];
        });
    }
}

- (MWKHistoryList *)recentPages {
    return self.dataStore.historyList;
}

- (MWKSavedPageList *)savedPages {
    return self.dataStore.savedPageList;
}

- (WMFArticle *)historyEntry {
    return [self.recentPages entryForURL:self.articleURL];
}

- (nullable WMFShareFunnel *)shareFunnel {
    NSParameterAssert(self.article);
    if (!self.article) {
        return nil;
    }
    if (!_shareFunnel) {
        _shareFunnel = [[WMFShareFunnel alloc] initWithArticle:self.article];
    }
    return _shareFunnel;
}

- (UIView *)headerView {
    if (!_headerView) {
        // HAX: Only read the scale at setup
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGFloat borderHeight = scale > 1 ? 0.5 : 1;
        CGFloat height = 10;

        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, height)];
        _headerView.clipsToBounds = YES;

        UIView *headerBorderView = [[UIView alloc] initWithFrame:CGRectMake(0, height - borderHeight, 1, borderHeight)];
        headerBorderView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        headerBorderView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;

        self.headerImageView.frame = CGRectMake(0, 0, 1, height - borderHeight);
        [_headerView addSubview:self.headerImageView];
        [_headerView addSubview:headerBorderView];
    }
    return _headerView;
}

- (UIImageView *)headerImageView {
    if (!_headerImageView) {
        _headerImageView = [[FLAnimatedImageView alloc] initWithFrame:CGRectZero];
        _headerImageView.userInteractionEnabled = YES;
        _headerImageView.clipsToBounds = YES;
        _headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        _headerImageView.accessibilityIgnoresInvertColors = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewDidTap:)];
        [_headerImageView addGestureRecognizer:tap];
    }
    return _headerImageView;
}

- (WMFArticleFetcher *)articleFetcher {
    if (!_articleFetcher) {
        _articleFetcher = [[WMFArticleFetcher alloc] initWithDataStore:self.dataStore];
    }
    return _articleFetcher;
}

- (WebViewController *)webViewController {
    if (!_webViewController) {
        _webViewController = [WebViewController wmf_initialViewControllerFromClassStoryboard];
        _webViewController.delegate = self;
        _webViewController.headerView = self.headerView;
    }
    return _webViewController;
}

#pragma mark - Notifications and Observations

- (void)applicationWillResignActiveWithNotification:(NSNotification *)note {
    [self saveWebViewScrollOffset];
    [self saveOpenArticleTitleWithCurrentlyOnscreenFragment];
}

- (void)articleWasUpdatedWithNotification:(NSNotification *)note {
    WMFArticle *article = [note object];
    NSString *articleKey = article.key;
    NSString *myDatabaseKey = self.articleURL.wmf_articleDatabaseKey;
    if (articleKey && myDatabaseKey && [articleKey isEqual:myDatabaseKey]) {
        [self updateSaveButtonStateForSaved:article.savedDate != nil];
    }
}

#pragma mark - WMFViewController

- (nullable UIScrollView *)scrollView {
    return self.webViewController.webView.scrollView;
}

- (void)scrollViewInsetsDidChange {
    [super scrollViewInsetsDidChange];
    [self updateTableOfContentsInsets];
}

- (void)updateTableOfContentsInsets {
    UIScrollView *scrollView = self.tableOfContentsViewController.tableView;
    BOOL wasAtTop = scrollView.contentOffset.y == 0 - scrollView.contentInset.top;
    if (self.tableOfContentsDisplayMode == WMFTableOfContentsDisplayModeInline) {
        scrollView.contentInset = self.scrollView.contentInset;
        scrollView.scrollIndicatorInsets = self.scrollView.scrollIndicatorInsets;
    } else {
        CGFloat top = self.view.safeAreaInsets.top;
        CGFloat bottom = self.view.safeAreaInsets.bottom;
        scrollView.contentInset = UIEdgeInsetsMake(top, 0, bottom, 0);
        scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(top, 0, bottom, 0);
    }
    if (wasAtTop) {
        scrollView.contentOffset = CGPointMake(0, 0 - scrollView.contentInset.top);
    }
}

#pragma mark - Public

- (BOOL)canRefresh {
    return self.article != nil;
}

- (BOOL)canShare {
    return self.article != nil;
}

- (BOOL)canAdjustText {
    return self.article != nil;
}

- (BOOL)canFindInPage {
    return self.article != nil;
}

- (BOOL)hasLanguages {
    return self.article.hasMultipleLanguages;
}

- (BOOL)hasTableOfContents {
    return self.article && !self.article.isMain && self.article.sections.count > 0;
}

- (BOOL)hasAboutThisArticle {
    return self.article && !self.article.isMain;
}

- (void)getShareText:(void (^)(NSString *text))completion {
    [self.webViewController.webView wmf_getSelectedText:^(NSString *_Nonnull text) {
        if (text.length == 0) {
            text = [self.article shareSnippet];
        }
        if (completion) {
            completion(text);
        }
    }];
}

#pragma mark - Toolbar Setup

- (NSArray<UIBarButtonItem *> *)articleToolBarItems {
    NSMutableArray *articleToolbarItems = [NSMutableArray arrayWithCapacity:18];

    CGFloat spacing = 0;
    switch (self.tableOfContentsDisplayMode) {
        case WMFTableOfContentsDisplayModeInline:
            spacing = 22;
            break;
        default:
            break;
    }

    NSArray *itemGroups = @[@[[UIBarButtonItem wmf_barButtonItemOfFixedWidth:spacing],
                              self.languagesToolbarItem,
                              [UIBarButtonItem wmf_barButtonItemOfFixedWidth:spacing]],

                            @[[UIBarButtonItem wmf_barButtonItemOfFixedWidth:3 + spacing],
                              self.saveToolbarItem,
                              [UIBarButtonItem wmf_barButtonItemOfFixedWidth:4 + spacing]],

                            @[[UIBarButtonItem wmf_barButtonItemOfFixedWidth:3 + spacing],
                              self.shareToolbarItem,
                              [UIBarButtonItem wmf_barButtonItemOfFixedWidth:3 + spacing]],

                            @[[UIBarButtonItem wmf_barButtonItemOfFixedWidth:spacing],
                              self.readingThemesControlsToolbarItem,
                              [UIBarButtonItem wmf_barButtonItemOfFixedWidth:spacing]],

                            @[[UIBarButtonItem wmf_barButtonItemOfFixedWidth:3 + spacing],

                              self.findInPageToolbarItem,
                              [UIBarButtonItem wmf_barButtonItemOfFixedWidth:8]]];

    for (NSArray *itemGroup in itemGroups) {
        switch (self.tableOfContentsDisplayMode) {
            case WMFTableOfContentsDisplayModeInline:
                break;
            case WMFTableOfContentsDisplayModeModal:
            default:
                [articleToolbarItems addObject:[UIBarButtonItem flexibleSpaceToolbarItem]];
                break;
        }
        [articleToolbarItems addObjectsFromArray:itemGroup];
    }

    UIBarButtonItem *tocItem = [self tableOfContentsToolbarItem];
    switch (self.tableOfContentsDisplayMode) {
        case WMFTableOfContentsDisplayModeInline:
            [articleToolbarItems insertObject:[UIBarButtonItem flexibleSpaceToolbarItem] atIndex:0];
            [articleToolbarItems addObject:[UIBarButtonItem flexibleSpaceToolbarItem]];
            [articleToolbarItems addObject:[UIBarButtonItem wmf_barButtonItemOfFixedWidth:tocItem.width + 8]];
        case WMFTableOfContentsDisplayModeModal:
        default: {
            WMFTableOfContentsDisplayStyle style = [self tableOfContentsStyleTweakValue];
            if (style == WMFTableOfContentsDisplayStyleOld) {
                id spacer = [articleToolbarItems objectAtIndex:0];
                [articleToolbarItems removeObjectAtIndex:0];
                [articleToolbarItems addObject:spacer];
                [articleToolbarItems addObject:tocItem];
            } else {
                [articleToolbarItems insertObject:tocItem atIndex:0];
            }
        } break;
    }
    return articleToolbarItems;
}

- (UIBarButtonItem *)tableOfContentsToolbarItem {
    switch (self.tableOfContentsDisplayState) {
        case WMFTableOfContentsDisplayStateInlineVisible:
            return self.hideTableOfContentsToolbarItem;
        default:
            return self.showTableOfContentsToolbarItem;
    }
}

- (void)updateToolbar {
    [self updateToolbarItemsIfNeeded];
    [self updateToolbarItemEnabledState];
}

- (void)updateToolbarItemsIfNeeded {

    NSArray<UIBarButtonItem *> *toolbarItems = [self articleToolBarItems];

    if (![self.toolbarItems isEqualToArray:toolbarItems]) {
        // HAX: only update toolbar if # of items has changed, otherwise items will (somehow) get lost
        [self setToolbarItems:toolbarItems animated:NO];
    }
}

- (void)updateToolbarItemEnabledState {
    self.readingThemesControlsToolbarItem.enabled = [self canAdjustText];
    self.shareToolbarItem.enabled = [self canShare];
    self.languagesToolbarItem.enabled = [self hasLanguages];
    self.showTableOfContentsToolbarItem.enabled = [self hasTableOfContents];
    self.findInPageToolbarItem.enabled = [self canFindInPage];
}

#pragma mark - Toolbar Items

- (UIBarButtonItem *)showTableOfContentsToolbarItem {
    if (!_showTableOfContentsToolbarItem) {
        _showTableOfContentsToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toc"]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(showTableOfContents:)];
        _showTableOfContentsToolbarItem.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"table-of-contents-button-label", nil, nil, @"Table of contents", @"Accessibility label for the Table of Contents button\n{{Identical|Table of contents}}");
        return _showTableOfContentsToolbarItem;
    }
    return _showTableOfContentsToolbarItem;
}

- (UIBarButtonItem *)hideTableOfContentsToolbarItem {
    if (!_hideTableOfContentsToolbarItem) {
        UIImage *closeImage = [UIImage imageNamed:@"toc"];
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeButton setImage:closeImage forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(hideTableOfContents:) forControlEvents:UIControlEventTouchUpInside];
        closeButton.frame = (CGRect){.origin = CGPointZero, .size = closeImage.size};
        closeButton.layer.cornerRadius = 5;
        closeButton.layer.masksToBounds = YES;
        _hideTableOfContentsToolbarItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        _hideTableOfContentsToolbarItem.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"table-of-contents-button-label", nil, nil, @"Table of contents", @"Accessibility label for the Table of Contents button\n{{Identical|Table of contents}}");
    }
    return _hideTableOfContentsToolbarItem;
}

- (UIBarButtonItem *)saveToolbarItem {
    if (!_saveToolbarItem) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 25, 25);
        [button setImage:[UIImage imageNamed:@"save"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(toggleSave:event:) forControlEvents:UIControlEventTouchUpInside];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleSaveButtonLongPressGestureRecognizer:)];
        [button addGestureRecognizer:longPress];
        _saveToolbarItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return _saveToolbarItem;
}

- (UIBarButtonItem *)readingThemesControlsToolbarItem {
    if (!_readingThemesControlsToolbarItem) {
        _readingThemesControlsToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"font-size"] style:UIBarButtonItemStylePlain target:self action:@selector(showReadingThemesControlsPopup)];
    }
    _readingThemesControlsToolbarItem.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"article-toolbar-reading-themes-controls-toolbar-item", nil, nil, @"Reading Themes Controls", @"Accessibility label for the Reading Themes Controls article toolbar item");
    return _readingThemesControlsToolbarItem;
}

- (UIBarButtonItem *)shareToolbarItem {
    if (!_shareToolbarItem) {
        _shareToolbarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                          target:self
                                                                          action:@selector(shareArticle)];
    }
    return _shareToolbarItem;
}

- (UIBarButtonItem *)findInPageToolbarItem {
    if (!_findInPageToolbarItem) {
        _findInPageToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"find-in-page"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(findInPageButtonPressed)];
        _findInPageToolbarItem.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"find-in-page-button-label", nil, nil, @"Find in page", @"Accessibility label for the Find in Page button");
    }
    return _findInPageToolbarItem;
}

- (void)findInPageButtonPressed {
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.webViewController showFindInPage];
    }];
    [self dismissReadingThemesPopoverIfActive];
    [CATransaction commit];
}

- (UIBarButtonItem *)languagesToolbarItem {
    if (!_languagesToolbarItem) {
        _languagesToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"language"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(showLanguagePicker)];
    }
    return _languagesToolbarItem;
}

#pragma mark - Article languages

- (void)showLanguagePicker {
    [self dismissReadingThemesPopoverIfActive];
    WMFArticleLanguagesViewController *languagesVC = [WMFArticleLanguagesViewController articleLanguagesViewControllerWithArticleURL:self.articleURL];
    languagesVC.delegate = self;
    [self presentViewControllerEmbeddedInNavigationController:languagesVC];
}

- (void)languagesController:(WMFLanguagesViewController *)controller didSelectLanguage:(MWKLanguageLink *)language {
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 [self pushArticleViewControllerWithURL:language.articleURL animated:YES];
                             }];
}

#pragma mark - Article Footers

- (void)updateTableOfContentsForFootersIfNeeded {
    if ([self.article.url wmf_isNonStandardURL]) {
        return;
    }
    if (![self hasTableOfContents]) {
        return;
    }

    BOOL includeReadMore = self.article.hasReadMore;

    [self appendItemsToTableOfContentsIncludingAboutThisArticle:[self hasAboutThisArticle] includeReadMore:includeReadMore];
}

#pragma mark - Progress

- (void)showProgressViewAnimated:(BOOL)animated {
    [self.navigationBar setProgressHidden:NO animated:animated];
}

- (void)hideProgressViewAnimated:(BOOL)animated {
    [self.navigationBar setProgressHidden:YES animated:animated];
}

- (void)updateProgress:(CGFloat)progress animated:(BOOL)animated {
    if (progress < self.navigationBar.progress) {
        return;
    }
    [self.navigationBar setProgress:progress animated:animated];

    [self.delegate articleController:self didUpdateArticleLoadProgress:progress animated:animated];
}

- (void)completeAndHideProgressWithCompletion:(nullable dispatch_block_t)completion {
    [self updateProgress:1.0 animated:YES];
    dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
        [self hideProgressViewAnimated:YES];
        if (completion) {
            completion();
        }
    });
}

/**
 *  Some of the progress is in loading the HTML into the webview
 *  This leaves 20% of progress for that work.
 */
- (CGFloat)totalProgressWithArticleFetcherProgress:(CGFloat)progress {
    return 0.1 + (0.7 * progress);
}

#pragma mark - Show search

- (void)ensureWikipediaSearchIsShowing {
    if (self.navigationBar.navigationBarPercentHidden > 0) {
        [self.navigationBar setNavigationBarPercentHidden:0];
    }
}

#pragma mark - Significantly Viewed Timer

- (void)startSignificantlyViewedTimer {
    if (self.significantlyViewedTimer) {
        return;
    }
    if (!self.article) {
        return;
    }
    MWKHistoryList *historyList = self.dataStore.historyList;
    WMFArticle *entry = [historyList entryForURL:self.articleURL];
    if (!entry.wasSignificantlyViewed) {
        self.significantlyViewedTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(significantlyViewedTimerFired:) userInfo:nil repeats:NO];
    }
}

- (void)significantlyViewedTimerFired:(NSTimer *)timer {
    [self stopSignificantlyViewedTimer];
    MWKHistoryList *historyList = self.dataStore.historyList;
    [historyList setSignificantlyViewedOnPageInHistoryWithURL:self.articleURL];
}

- (void)stopSignificantlyViewedTimer {
    [self.significantlyViewedTimer invalidate];
    self.significantlyViewedTimer = nil;
}

#pragma mark - Title Button

- (UIButton *)titleButton {
    return (UIButton *)self.navigationItem.titleView;
}

- (void)setUpTitleBarButton {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b adjustsImageWhenHighlighted];
    UIImage *w = [UIImage imageNamed:@"W"];
    [b setImage:w forState:UIControlStateNormal];
    [b sizeToFit];
    [b addTarget:self action:@selector(titleBarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.titleView = b;
    self.navigationItem.titleView.isAccessibilityElement = YES;

    self.navigationItem.titleView.accessibilityTraits |= UIAccessibilityTraitButton;
}

- (void)titleBarButtonPressed {
    [self dismissReadingThemesPopoverIfActive];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - ViewController

- (void)viewDidLoad {
    if (@available(iOS 12, *)) {
        self.subtractTopAndBottomSafeAreaInsetsFromScrollIndicatorInsets = YES;
    }
    self.savedPagesFunnel = [[SavedPagesFunnel alloc] init];
    [self setUpTitleBarButton];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveWithNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleWasUpdatedWithNotification:) name:WMFArticleUpdatedNotification object:nil];

    self.tableOfContentsSeparatorView = [[UIView alloc] init];
    [self setupWebView];

    [self hideProgressViewAnimated:NO];

    self.eventLoggingCategory = EventLoggingCategoryArticle;
    self.eventLoggingLabel = EventLoggingLabelOutLink;

    self.imageScaleTransitionView = self.headerImageView;

    self.navigationBar.isExtendedViewHidingEnabled = YES;
    self.navigationBar.isShadowBelowUnderBarView = YES;
    self.navigationBar.isExtendedViewFadingEnabled = NO;
    [super viewDidLoad]; // intentionally at the bottom of the method for theme application
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSUInteger index = self.indexOfCurrentFontSize;
    NSNumber *multiplier = self.fontSizeMultipliers[index];
    [self.webViewController setFontSizeMultiplier:multiplier];

    [self updateTableOfContentsDisplayModeWithTraitCollection:self.traitCollection];

    BOOL isVisibleInline = [[NSUserDefaults wmf] wmf_isTableOfContentsVisibleInline];

    self.tableOfContentsDisplayState = self.tableOfContentsDisplayMode == WMFTableOfContentsDisplayModeInline ? isVisibleInline ? WMFTableOfContentsDisplayStateInlineVisible : WMFTableOfContentsDisplayStateInlineHidden : WMFTableOfContentsDisplayStateModalHidden;

    [self updateToolbar];

    [self layoutForSize:self.view.bounds.size];

    [self registerForPreviewingIfAvailable];

    if (!self.skipFetchOnViewDidAppear) {
        [self fetchArticleIfNeeded];
    }
    self.skipFetchOnViewDidAppear = NO;
    [self startSignificantlyViewedTimer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self saveOpenArticleTitleWithCurrentlyOnscreenFragment];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self unregisterForPreviewing];

    [self stopSignificantlyViewedTimer];
    [self saveWebViewScrollOffset];
    [self dismissReadingThemesPopoverIfActive];

    [self cancelWIconPopoverDisplay];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.reachabilityNotifier stop];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    //TODO: Is this needed? iBooks doesn't dismiss the popover on rotation.
    //    if ([self.presentedViewController isKindOfClass:[WMFReadingThemesControlsViewController class]]) {
    //        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    //    }
    [self registerForPreviewingIfAvailable];
    NSNumber *multiplier = [[NSUserDefaults wmf] wmf_articleFontSizeMultiplier];
    [self.webViewController setFontSizeMultiplier:multiplier];
}

#pragma mark - WMFImageScaleTransitionProviding
- (void)removeHeaderImageTransitionView {
    if (!self.headerImageTransitionView) {
        return;
    }
    UIImageView *transitionView = self.headerImageTransitionView;
    self.headerImageTransitionView = nil;
    [UIView animateWithDuration:0.2
        animations:^{
            self.webViewController.view.alpha = 1;
        }
        completion:^(BOOL finished) {
            [transitionView removeFromSuperview];
        }];
}

- (void)prepareForIncomingImageScaleTransitionWithImageView:(nullable UIImageView *)imageView {
    if (imageView && imageView.image) {
        self.webViewController.headerFadingEnabled = NO;
        self.webViewController.view.alpha = 0;

        self.headerImageTransitionView = [[UIImageView alloc] initWithFrame:self.headerImageView.frame];
        self.headerImageTransitionView.translatesAutoresizingMaskIntoConstraints = NO;
        self.headerImageTransitionView.image = imageView.image;
        self.headerImageTransitionView.layer.contentsRect = imageView.layer.contentsRect;
        self.headerImageTransitionView.contentMode = imageView.contentMode;
        self.headerImageTransitionView.clipsToBounds = YES;
        [self.view insertSubview:self.headerImageTransitionView belowSubview:self.webViewController.view];

        NSLayoutConstraint *headerImageTransitionTopConstraint = [self.headerImageTransitionView.topAnchor constraintEqualToAnchor:self.navigationBar.bottomAnchor];
        NSLayoutConstraint *headerImageTransitionLeadingConstraint = [self.headerImageTransitionView.leadingAnchor constraintEqualToAnchor:self.headerImageView.leadingAnchor];
        NSLayoutConstraint *headerImageTransitionTrailingConstraint = [self.headerImageTransitionView.trailingAnchor constraintEqualToAnchor:self.headerImageView.trailingAnchor];
        NSLayoutConstraint *headerImageTransitionHeightConstraint = [self.headerImageTransitionView.heightAnchor constraintEqualToConstant:WebViewControllerHeaderImageHeight];
        [self.view addConstraints:@[headerImageTransitionTopConstraint, headerImageTransitionLeadingConstraint, headerImageTransitionTrailingConstraint, headerImageTransitionHeightConstraint]];

        self.headerImageView.image = imageView.image;
        self.headerImageView.layer.contentsRect = imageView.layer.contentsRect;

        [self.view layoutIfNeeded];
    }
}

#pragma mark - Layout

- (void)layoutForSize:(CGSize)size {
    BOOL isTOCVisible = self.tableOfContentsDisplayState == WMFTableOfContentsDisplayStateInlineVisible;

    CGFloat separatorWidth = WMFArticleViewControllerTableOfContentsSeparatorWidth;
    CGFloat tocWidth = round(size.width * WMFArticleViewControllerExpandedTableOfContentsWidthPercentage);
    CGFloat webFrameWidth = size.width - (isTOCVisible ? (separatorWidth + tocWidth) : 0);

    CGFloat webFrameOriginX;
    CGFloat tocOriginX;
    CGFloat separatorOriginX;

    switch (self.tableOfContentsDisplaySide) {
        case WMFTableOfContentsDisplaySideRight:
            tocOriginX = isTOCVisible ? webFrameWidth + separatorWidth : size.width + separatorWidth;
            separatorOriginX = isTOCVisible ? webFrameWidth : size.width;
            webFrameOriginX = 0;
            break;
        case WMFTableOfContentsDisplaySideLeft:
        default:
            tocOriginX = isTOCVisible ? 0 : 0 - tocWidth - separatorWidth;
            separatorOriginX = isTOCVisible ? tocWidth : 0 - separatorWidth;
            webFrameOriginX = tocOriginX + tocWidth + separatorWidth;
            break;
    }

    CGPoint origin = CGPointZero;
    if (self.tableOfContentsDisplayMode != WMFTableOfContentsDisplayModeModal) {
        self.tableOfContentsViewController.view.frame = CGRectMake(tocOriginX, 0, tocWidth, size.height);
        self.tableOfContentsSeparatorView.frame = CGRectMake(separatorOriginX, 0, separatorWidth, size.height);
        self.tableOfContentsViewController.view.alpha = isTOCVisible ? 1 : 0;
        self.tableOfContentsSeparatorView.alpha = isTOCVisible ? 1 : 0;
    }

    CGRect webFrame = CGRectMake(webFrameOriginX, origin.y, webFrameWidth, size.height);
    self.webViewController.view.frame = webFrame;
    switch (self.tableOfContentsDisplayState) {
        case WMFTableOfContentsDisplayStateInlineHidden:
            self.webViewController.contentWidthPercentage = 0.70;
            break;
        case WMFTableOfContentsDisplayStateInlineVisible:
            self.webViewController.contentWidthPercentage = 0.90;
            break;
        default:
            self.webViewController.contentWidthPercentage = 0.90;
            break;
    }

    [self.webViewController.view layoutIfNeeded];

    [self layoutHeaderImageViewForSize:size];
}

- (void)layoutHeaderImageViewForSize:(CGSize)size {
    CGRect headerViewBounds = self.headerView.bounds;

    self.headerView.bounds = headerViewBounds;
    CGSize imageSize = self.headerImageView.image.size;
    BOOL isImageNarrow = imageSize.width / imageSize.height < 2;
    CGFloat marginWidth = 0;
    if (isImageNarrow && self.tableOfContentsDisplayState == WMFTableOfContentsDisplayStateInlineHidden) {
        marginWidth = self.webViewController.marginWidth + 16;
    }
    self.headerImageView.frame = CGRectMake(marginWidth, 0, headerViewBounds.size.width - 2 * marginWidth, WebViewControllerHeaderImageHeight);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutForSize:self.view.bounds.size];
}

- (WMFTableOfContentsDisplayStyle)tableOfContentsStyleTweakValue {
#if WMF_TWEAKS_ENABLED
    return FBTweakValue(@"Table of contents", @"Style", @"0:old 1:now 2:new", 1, 0, 2);
#else
    return WMFTableOfContentsDisplayStyleCurrent;
#endif
}

- (void)updateTableOfContentsDisplayModeWithTraitCollection:(UITraitCollection *)traitCollection {

    BOOL isCompact = traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;

    if (isCompact) {
        WMFTableOfContentsDisplayStyle style = [self tableOfContentsStyleTweakValue];
        switch (style) {
            case WMFTableOfContentsDisplayStyleOld:
                self.tableOfContentsDisplaySide = [[UIApplication sharedApplication] wmf_tocShouldBeOnLeft] ? WMFTableOfContentsDisplaySideRight : WMFTableOfContentsDisplaySideLeft;
                break;
            case WMFTableOfContentsDisplayStyleNext:
                self.tableOfContentsDisplaySide = WMFTableOfContentsDisplaySideCenter;
                break;
            case WMFTableOfContentsDisplayStyleCurrent:
            default:
                self.tableOfContentsDisplaySide = [[UIApplication sharedApplication] wmf_tocShouldBeOnLeft] ? WMFTableOfContentsDisplaySideLeft : WMFTableOfContentsDisplaySideRight;
                break;
        }
    } else {
        self.tableOfContentsDisplaySide = [[UIApplication sharedApplication] wmf_tocShouldBeOnLeft] ? WMFTableOfContentsDisplaySideLeft : WMFTableOfContentsDisplaySideRight;
    }

    self.tableOfContentsDisplayMode = isCompact ? WMFTableOfContentsDisplayModeModal : WMFTableOfContentsDisplayModeInline;
    switch (self.tableOfContentsDisplayMode) {
        case WMFTableOfContentsDisplayModeInline:
            self.updateTableOfContentsSectionOnScrollEnabled = YES;
            break;
        case WMFTableOfContentsDisplayModeModal:
        default:
            self.updateTableOfContentsSectionOnScrollEnabled = NO;
            break;
    }

    self.tableOfContentsViewController.displayMode = self.tableOfContentsDisplayMode;
    self.tableOfContentsViewController.displaySide = self.tableOfContentsDisplaySide;

    [self updateTableOfContentsInsets];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [self updateTableOfContentsDisplayModeWithTraitCollection:newCollection];
    [self setupTableOfContentsViewController];
}

#pragma mark - Web View Setup

- (void)setupWebView {
    self.webViewController.edgesForExtendedLayout = UIRectEdgeAll;
    self.webViewController.extendedLayoutIncludesOpaqueBars = YES;
    self.webViewController.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self addChildViewController:self.webViewController];
    [self.view insertSubview:self.webViewController.view atIndex:0];
    [self.webViewController didMoveToParentViewController:self];

    self.pullToRefresh = [[UIRefreshControl alloc] init];
    self.pullToRefresh.enabled = [self canRefresh];
    [self.pullToRefresh addTarget:self action:@selector(fetchArticle) forControlEvents:UIControlEventValueChanged];
    [self.webViewController.webView.scrollView addSubview:_pullToRefresh];
}

#pragma mark - Table of Contents

- (void)updateTableOfContentsLayoutAnimated:(BOOL)animated {
    if (animated) {

        void (^makeLayoutAdjustments)(void) = ^{
            UIScrollView *scrollView = self.webViewController.webView.scrollView;
            CGFloat previousOffsetPercentage = scrollView.contentOffset.y / scrollView.contentSize.height;

            [self layoutForSize:self.view.bounds.size];
            if (self.sectionToRestoreScrollOffset) {
                [self.webViewController scrollToSection:self.currentSection animated:NO];
            } else {
                scrollView.contentOffset = CGPointMake(0, previousOffsetPercentage * scrollView.contentSize.height);
            }
        };

        // Fade the web view out fully.
        [UIView animateWithDuration:0.15
            delay:0.0
            options:UIViewAnimationOptionBeginFromCurrentState
            animations:^{
                self.webViewController.view.alpha = 0.0;
            }
            completion:^(BOOL finished) {
                // Make layout adjustments. These trigger a web view width change, which triggers an unanimatable (slightly 'jerky') text-reflow, which is why we ensure the web view is faded out for this step.
                [UIView animateWithDuration:0.15
                                      delay:0.0
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:makeLayoutAdjustments
                                 completion:^(BOOL finished) {
                                     // Then fade the web view back in.
                                     [UIView animateWithDuration:0.1
                                                           delay:0.05 // Important! Slight delay ensures text reflow *and* contentOffset changes have completely finished (otherwise you can sometimes get another frame or 2 of flicker).
                                                         options:UIViewAnimationOptionBeginFromCurrentState
                                                      animations:^{
                                                          self.webViewController.view.alpha = 1.0;
                                                      }
                                                      completion:NULL];
                                 }];
            }];
    } else {
        [self layoutForSize:self.view.bounds.size];
    }
}

- (void)showTableOfContents:(id)sender {
    [self dismissReadingThemesPopoverIfActive];

    if (self.tableOfContentsViewController == nil) {
        return;
    }

    self.tableOfContentsViewController.displayMode = self.tableOfContentsDisplayMode;
    self.tableOfContentsViewController.displaySide = self.tableOfContentsDisplaySide;

    switch (self.tableOfContentsDisplayMode) {
        case WMFTableOfContentsDisplayModeInline:
            if (sender != self) {
                [[NSUserDefaults wmf] wmf_setTableOfContentsIsVisibleInline:YES];
            }
            self.tableOfContentsDisplayState = WMFTableOfContentsDisplayStateInlineVisible;
            [self updateTableOfContentsLayoutAnimated:YES];
            break;
        case WMFTableOfContentsDisplayModeModal:
        default:
            self.tableOfContentsDisplayState = WMFTableOfContentsDisplayStateModalVisible;
            [self presentViewController:self.tableOfContentsViewController animated:YES completion:NULL];
    }
    [self updateToolbar];
}

- (void)hideTableOfContents:(id)sender {
    switch (self.tableOfContentsDisplayMode) {
        case WMFTableOfContentsDisplayModeInline:
            if (sender != self) {
                [[NSUserDefaults wmf] wmf_setTableOfContentsIsVisibleInline:NO];
            }
            self.tableOfContentsDisplayState = WMFTableOfContentsDisplayStateInlineHidden;
            [self updateTableOfContentsLayoutAnimated:YES];
            break;
        case WMFTableOfContentsDisplayModeModal:
        default:
            self.tableOfContentsDisplayState = WMFTableOfContentsDisplayStateModalHidden;
            [self dismissViewControllerAnimated:YES completion:NULL];
    }
    [self updateToolbar];
}

- (void)setupTableOfContentsViewController {
    switch (self.tableOfContentsDisplayMode) {
        case WMFTableOfContentsDisplayModeInline: {
            if (self.tableOfContentsViewController.parentViewController != self) {
                if (self.presentedViewController == self.tableOfContentsViewController) {
                    [self.tableOfContentsViewController dismissViewControllerAnimated:NO completion:NULL];
                }
                self.tableOfContentsViewController = nil;

                switch (self.tableOfContentsDisplayState) {
                    case WMFTableOfContentsDisplayStateModalHidden:
                        self.tableOfContentsDisplayState = WMFTableOfContentsDisplayStateInlineHidden;
                        break;
                    case WMFTableOfContentsDisplayStateModalVisible:
                        self.tableOfContentsDisplayState = WMFTableOfContentsDisplayStateInlineVisible;
                    default:
                        break;
                }

                [self createTableOfContentsViewControllerIfNeeded];
                self.tableOfContentsViewController.displayMode = self.tableOfContentsDisplayMode;
                self.tableOfContentsViewController.displaySide = self.tableOfContentsDisplaySide;

                if (self.tableOfContentsViewController == nil) {
                    self.tableOfContentsDisplayState = WMFTableOfContentsDisplayStateInlineHidden;
                } else {
                    [self addChildViewController:self.tableOfContentsViewController];
                    [self.view insertSubview:self.tableOfContentsViewController.view aboveSubview:self.webViewController.view];
                    [self.tableOfContentsViewController didMoveToParentViewController:self];

                    [self.view insertSubview:self.tableOfContentsSeparatorView aboveSubview:self.tableOfContentsViewController.view];

                    self.tableOfContentsCloseGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTableOfContentsCloseGesture:)];
                    UISwipeGestureRecognizerDirection closeDirection;
                    switch (self.tableOfContentsDisplaySide) {
                        case WMFTableOfContentsDisplaySideRight:
                            closeDirection = UISwipeGestureRecognizerDirectionRight;
                            break;
                        case WMFTableOfContentsDisplaySideLeft:
                        default:
                            closeDirection = UISwipeGestureRecognizerDirectionLeft;
                            break;
                    }
                    self.tableOfContentsCloseGestureRecognizer.direction = closeDirection;
                    [self.tableOfContentsViewController.view addGestureRecognizer:self.tableOfContentsCloseGestureRecognizer];
                }
            }
        } break;
        default:
        case WMFTableOfContentsDisplayModeModal: {
            if (self.tableOfContentsViewController.parentViewController == self) {
                [self.tableOfContentsViewController willMoveToParentViewController:nil];
                [self.tableOfContentsViewController.view removeFromSuperview];
                [self.tableOfContentsViewController removeFromParentViewController];
                [self.tableOfContentsSeparatorView removeFromSuperview];
                self.tableOfContentsViewController = nil;
            }
            [self createTableOfContentsViewControllerIfNeeded];
            self.tableOfContentsViewController.displayMode = self.tableOfContentsDisplayMode;
            self.tableOfContentsViewController.displaySide = self.tableOfContentsDisplaySide;

            switch (self.tableOfContentsDisplayState) {
                case WMFTableOfContentsDisplayStateInlineVisible:
                    self.tableOfContentsDisplayState = WMFTableOfContentsDisplayStateModalVisible;
                    [self showTableOfContents:self];
                    break;
                case WMFTableOfContentsDisplayStateInlineHidden:
                default:
                    self.tableOfContentsDisplayState = WMFTableOfContentsDisplayStateModalHidden;
                    break;
            }

        } break;
    }
    [self updateToolbar];
    [self updateTableOfContentsInsets];
}

- (void)handleTableOfContentsCloseGesture:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.tableOfContentsDisplayState == WMFTableOfContentsDisplayStateInlineVisible) {
            [self hideTableOfContents:recognizer];
        }
    }
}

#pragma mark - Save Offset

- (void)saveWebViewScrollOffset {
    // Don't record scroll position of "main" pages.
    if (self.article.isMain) {
        return;
    }
    CGFloat offset = [self.webViewController currentVerticalOffset];
    [self.webViewController getCurrentVisibleSectionCompletion:^(MWKSection *_Nullable section, NSError *_Nullable error) {
        self.currentSection = section;
        [self.recentPages setFragment:self.currentSection.anchor scrollPosition:offset onPageInHistoryWithURL:self.articleURL];
    }];
}

#pragma mark - Article Fetching

- (void)articleDidLoad {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *navigationTitle = self.article.displaytitle.wmf_stringByRemovingHTML;
        if ([navigationTitle length] > 16) {
            navigationTitle = nil;
        }
        self.navigationItem.title = navigationTitle;
        dispatch_block_t completion = self.articleLoadCompletion;
        if (completion) {
            completion();
            self.articleLoadCompletion = nil;
        }
    });
}

- (void)endRefreshing {
    if (self.pullToRefresh.isRefreshing) {
        @try { // TODO: REMOVE AFTER DROPPING iOS 9
            [self.pullToRefresh endRefreshing];
        } @catch (NSException *exception) {
            DDLogError(@"Caught exception while ending refreshing: %@", exception);
        }
    }
}

- (void)fetchArticleForce:(BOOL)force {
    // ** Always call articleDidLoad after the article loads or fails & before returning from this method **
    WMFAssertMainThread(@"Not on main thread!");
    NSAssert(self.isViewLoaded, @"Should only fetch article when view is loaded so we can update its state.");
    if (!force && self.article) {
        [self endRefreshing];
        [self articleDidLoad];
        return;
    }

    [self updateProgress:0.1 animated:NO]; //initial progress is 0.1, incorporated with totalProgressWithArticleFetcherProgress
    [self showProgressViewAnimated:YES];

    @weakify(self);
    self.articleFetcherPromise = [self.articleFetcher fetchLatestVersionOfArticleWithURL:self.articleURL
        forceDownload:force
        saveToDisk:NO
        priority:NSURLSessionTaskPriorityHigh
        progress:^(CGFloat progress) {
            [self updateProgress:[self totalProgressWithArticleFetcherProgress:progress] animated:YES];
        }
        failure:^(NSError *_Nonnull error) {
            @strongify(self);
            DDLogError(@"Article Fetch Error: %@", [error localizedDescription]);
            [self endRefreshing];
            [self hideProgressViewAnimated:YES];
            [self.delegate articleControllerDidLoadArticle:self];

            MWKArticle *cachedFallback = error.userInfo[WMFArticleFetcherErrorCachedFallbackArticleKey];
            if (cachedFallback) {
                self.article = cachedFallback;
                if (![error wmf_isNetworkConnectionError]) {
                    // don't show offline banner for cached articles
                    [[WMFAlertManager sharedInstance] showErrorAlert:error
                                                              sticky:NO
                                               dismissPreviousAlerts:NO
                                                         tapCallBack:NULL];
                }
            } else if ([error wmf_isWMFErrorMissingTitle]) {
                NSUserActivity *specialPageActivity = [NSUserActivity wmf_specialPageActivityWithURL:self.articleURL];
                if (specialPageActivity) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:WMFNavigateToActivityNotification object:specialPageActivity];
                    [self.navigationController popViewControllerAnimated:NO];
                    return;
                } else {
                    [[WMFAlertManager sharedInstance] showErrorAlert:error
                                                              sticky:NO
                                               dismissPreviousAlerts:NO
                                                         tapCallBack:NULL];
                }
            } else {
                [self wmf_showEmptyViewOfType:WMFEmptyViewTypeArticleDidNotLoad action:nil theme:self.theme frame:self.view.bounds];
                [[WMFAlertManager sharedInstance] showErrorAlert:error
                                                          sticky:NO
                                           dismissPreviousAlerts:NO
                                                     tapCallBack:NULL];

                if ([error wmf_isNetworkConnectionError]) {
                    [self.reachabilityNotifier start];
                }
            }

            self.articleFetcherPromise = nil;
            [self articleDidLoad];
            [self removeHeaderImageTransitionView]; // remove here on failure, on web view callback on success
        }
        success:^(MWKArticle *_Nonnull article) {
            @strongify(self);
            [self endRefreshing];
            [self updateProgress:[self totalProgressWithArticleFetcherProgress:1.0] animated:YES];
            self.article = article;
            self.articleFetcherPromise = nil;
            [self articleDidLoad];
        }];
}

- (void)fetchArticle {
    [self fetchArticleForce:YES];
}

- (void)fetchArticleIfNeeded {
    [self fetchArticleForce:NO];
}

#pragma mark - Share

- (void)shareAFactWithTextSnippet:(nullable NSString *)text {
    WMFArticle *article = [self.dataStore fetchArticleWithURL:self.articleURL];
    if (!article) {
        return;
    }

    WMFShareViewController *shareViewController = [[WMFShareViewController alloc] initWithText:text article:article theme:self.theme];
    [self presentViewController:shareViewController animated:YES completion:nil];
}

- (void)shareArticle {
    [self dismissReadingThemesPopoverIfActive];

    [self.webViewController.webView wmf_getSelectedText:^(NSString *_Nonnull text) {
        if (text.length > 0) {
            WMFCustomShareActivity *shareAFactActivity = [[WMFCustomShareActivity alloc] initWithTitle:@"Share-a-fact"
                                                                                             imageName:@"share-a-fact"
                                                                                                action:^{
                                                                                                    [self.shareFunnel logHighlight];
                                                                                                    [self shareAFactWithTextSnippet:text];
                                                                                                }];
            UIActivityViewController *vc = [self.article sharingActivityViewControllerWithTextSnippet:nil fromButton:self->_shareToolbarItem shareFunnel:self.shareFunnel customActivity:shareAFactActivity];
            if (vc) {
                [self presentViewController:vc animated:YES completion:NULL];
            }
            return;
        } else {
            NSURL *articleURL = self.articleURL;
            UIActivityViewController *vc = [self.article sharingActivityViewControllerWithTextSnippet:nil
                                                                                           fromButton:self->_shareToolbarItem
                                                                                          shareFunnel:self.shareFunnel
                                                                                       customActivity:[self addToReadingListActivityWithPresenter:self
                                                                                                                                   eventLogAction:^{
                                                                                                                                       [[ReadingListsFunnel shared] logArticleSaveInCurrentArticle:articleURL];
                                                                                                                                   }]];
            vc.excludedActivityTypes = @[UIActivityTypeAddToReadingList];
            if (vc) {
                [self presentViewController:vc animated:YES completion:NULL];
            }
        }
    }];
}

- (nullable UIActivity *)addToReadingListActivityWithPresenter:(UIViewController *)presenter eventLogAction:(nullable void (^)(void))eventLogAction {
    WMFArticle *article = [self.dataStore fetchArticleWithURL:self.articleURL];
    if (!article) {
        return nil;
    }

    WMFAddToReadingListActivity *addToReadingListActivity = [[WMFAddToReadingListActivity alloc] initWithAction:^{
        WMFAddArticlesToReadingListViewController *addArticlesToReadingListViewController = [[WMFAddArticlesToReadingListViewController alloc] initWith:self.dataStore articles:@[article] moveFromReadingList:nil theme:self.theme];
        addArticlesToReadingListViewController.eventLogAction = eventLogAction;
        WMFThemeableNavigationController *navigationController = [[WMFThemeableNavigationController alloc] initWithRootViewController:addArticlesToReadingListViewController theme:self.theme];
        [navigationController setNavigationBarHidden:YES];
        [presenter presentViewController:navigationController animated:YES completion:NULL];
        ;
    }];

    return addToReadingListActivity;
}

- (void)shareArticleWhenReady {
    if (self.canShare) {
        [self shareArticle];
    } else {
        self.shareArticleOnLoad = YES;
    }
}

#pragma mark - Save

- (void)toggleSave:(id)sender event:(UIEvent *)event {
    [self dismissReadingThemesPopoverIfActive];
    WMFArticle *articleToUnsave = [self.savedPages entryForURL:self.articleURL];
    if (articleToUnsave && articleToUnsave.userCreatedReadingListsCount > 0) {
        WMFReadingListsAlertController *readingListsAlertController = [[WMFReadingListsAlertController alloc] init];
        [readingListsAlertController showAlertWithPresenter:self article:articleToUnsave];
        return; // don't unsave immediately, wait for a callback from WMFReadingListsAlertControllerDelegate
    }
    [self updateSavedState];
}

- (void)updateSaveButtonStateForSaved:(BOOL)isSaved {
    self.saveToolbarItem.accessibilityLabel = isSaved ? [WMFCommonStrings accessibilitySavedTitle] : [WMFCommonStrings saveTitle];
    if ([self.saveToolbarItem.customView isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)self.saveToolbarItem.customView;
        if (isSaved) {
            [button setImage:[UIImage imageNamed:@"save-filled"] forState:UIControlStateNormal];
        } else {
            [button setImage:[UIImage imageNamed:@"save"] forState:UIControlStateNormal];
        }
    }
}

- (void)updateSavedState {
    BOOL isSaved = [self.savedPages toggleSavedPageForURL:self.articleURL];
    if (isSaved) {
        [self.savedPagesFunnel logSaveNewWithArticleURL:self.articleURL];
        [[ReadingListsFunnel shared] logArticleSaveInCurrentArticle:self.articleURL];
    } else {
        [self.savedPagesFunnel logDeleteWithArticleURL:self.articleURL];
        [[ReadingListsFunnel shared] logArticleUnsaveInCurrentArticle:self.articleURL];
    }
    [self.readingListHintController didSave:isSaved articleURL:self.articleURL theme:self.theme];
}

- (void)handleSaveButtonLongPressGestureRecognizer:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (longPressGestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    WMFArticle *article = [self.dataStore fetchArticleWithURL:self.articleURL];
    WMFAddArticlesToReadingListViewController *addArticlesToReadingListViewController = [[WMFAddArticlesToReadingListViewController alloc] initWith:self.dataStore articles:@[article] moveFromReadingList:nil theme:self.theme];
    WMFThemeableNavigationController *navigationController = [[WMFThemeableNavigationController alloc] initWithRootViewController:addArticlesToReadingListViewController theme:self.theme];
    [navigationController setNavigationBarHidden:NO];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - WMFReadingListsAlertControllerDelegate

- (void)readingListsAlertController:(WMFReadingListsAlertController *)readingListsAlertController didSelectUnsaveForArticle:(WMFArticle *_Nonnull)article {
    [self updateSavedState];
}

#pragma mark - Reading Themes Controls

- (void)setupReadingThemesControls {
    self.readingThemesViewController = [[WMFReadingThemesControlsViewController alloc] initWithNibName:@"ReadingThemesControlsViewController" bundle:nil];
}

- (void)showReadingThemesControlsPopup {
    NSArray *fontSizes = self.fontSizeMultipliers;
    NSUInteger index = self.indexOfCurrentFontSize;

    self.readingThemesViewController.modalPresentationStyle = UIModalPresentationPopover;

    self.readingThemesViewController.delegate = self;

    [self.readingThemesViewController setValuesWithSteps:fontSizes.count current:index];

    self.readingThemesPopoverPresenter = [self.readingThemesViewController popoverPresentationController];

    [self.readingThemesViewController applyTheme:self.theme];

    self.readingThemesPopoverPresenter.delegate = self;
    self.readingThemesPopoverPresenter.barButtonItem = self.readingThemesControlsToolbarItem;
    self.readingThemesPopoverPresenter.permittedArrowDirections = UIPopoverArrowDirectionDown;

    self.readingThemesPopoverPresenter.backgroundColor = self.theme.colors.popoverBackground;

    [self presentViewController:self.readingThemesViewController animated:YES completion:nil];

    self.readingThemesPopoverPresenter.passthroughViews = [NSArray arrayWithObject:self.navigationController.navigationBar];
}

- (void)dismissReadingThemesPopoverIfActive {
    if ([self.presentedViewController isKindOfClass:[WMFReadingThemesControlsViewController class]]) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    // This method is called in iOS 8.3 or later regardless of trait collection, in which case use the original presentation style (UIModalPresentationNone signals no adaptation)
    return UIModalPresentationNone;
}

- (void)fontSizeSliderValueChangedInController:(WMFReadingThemesControlsViewController *)container value:(NSInteger)value {
    NSArray *fontSizes = self.fontSizeMultipliers;

    if (value > fontSizes.count) {
        return;
    }

    NSNumber *multiplier = self.fontSizeMultipliers[value];
    [self.webViewController setFontSizeMultiplier:multiplier];
    [[NSUserDefaults wmf] wmf_setArticleFontSizeMultiplier:multiplier];
}

- (void)themeChangedInArticleControls:(WMFReadingThemesControlsViewController *_Nonnull)controller theme:(WMFTheme *_Nonnull)theme {
}

- (NSArray<NSNumber *> *)fontSizeMultipliers {
#if WMF_TWEAKS_ENABLED
    return @[@(FBTweakValue(@"Article", @"Font Size", @"Step 1", WMFFontSizeMultiplierExtraSmall)),
             @(FBTweakValue(@"Article", @"Font Size", @"Step 2", WMFFontSizeMultiplierSmall)),
             @(FBTweakValue(@"Article", @"Font Size", @"Step 3", WMFFontSizeMultiplierMedium)),
             @(FBTweakValue(@"Article", @"Font Size", @"Step 4", WMFFontSizeMultiplierLarge)),
             @(FBTweakValue(@"Article", @"Font Size", @"Step 5", WMFFontSizeMultiplierExtraLarge)),
             @(FBTweakValue(@"Article", @"Font Size", @"Step 6", WMFFontSizeMultiplierExtraExtraLarge)),
             @(FBTweakValue(@"Article", @"Font Size", @"Step 7", WMFFontSizeMultiplierExtraExtraExtraLarge))];
#else
    return @[@(WMFFontSizeMultiplierExtraSmall),
             @(WMFFontSizeMultiplierSmall),
             @(WMFFontSizeMultiplierMedium),
             @(WMFFontSizeMultiplierLarge),
             @(WMFFontSizeMultiplierExtraLarge),
             @(WMFFontSizeMultiplierExtraExtraLarge),
             @(WMFFontSizeMultiplierExtraExtraExtraLarge)];
#endif
}

- (NSUInteger)indexOfCurrentFontSize {
    NSNumber *fontSize = [[NSUserDefaults wmf] wmf_articleFontSizeMultiplier];

    NSUInteger index = [[self fontSizeMultipliers] indexOfObject:fontSize];

    if (index == NSNotFound) {
        index = [self fontSizeMultipliers].count / 2;
    }

    return index;
}

#pragma mark - WMFWebViewControllerDelegate

- (void)webViewController:(WebViewController *)controller
    didTapImageWithSourceURL:(nonnull NSURL *)imageSourceURL {
    MWKImage *selectedImage = [[MWKImage alloc] initWithArticle:self.article sourceURL:imageSourceURL];
    WMFArticleImageGalleryViewController *fullscreenGallery = [[WMFArticleImageGalleryViewController alloc] initWithArticle:self.article selectedImage:selectedImage theme:self.theme overlayViewTopBarHidden:NO];
    if (fullscreenGallery != nil) {
        [self presentViewController:fullscreenGallery animated:YES completion:nil];
    }
}

- (void)webViewController:(WebViewController *)controller didLoadArticle:(MWKArticle *)article {
    [self removeHeaderImageTransitionView];

    [self completeAndHideProgressWithCompletion:^{
        //Without this pause, the motion happens too soon after loading the article
        dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
            [self showWIconPopoverIfNecessary];
        });
    }];

    if (self.tableOfContentsDisplayMode != WMFTableOfContentsDisplayModeModal) {
        [self setupTableOfContentsViewController];
        [self layoutForSize:self.view.bounds.size];
        [self.tableOfContentsViewController selectAndScrollToItemAtIndex:0 animated:NO];
    }

    [self.delegate articleControllerDidLoadArticle:self];

    [self saveOpenArticleTitleWithCurrentlyOnscreenFragment];
}

- (void)saveOpenArticleTitleWithCurrentlyOnscreenFragment {
    if (self.navigationController.topViewController != self || !self.isSavingOpenArticleTitleEnabled) {
        return;
    }

    [self.webViewController getCurrentVisibleSectionCompletion:^(MWKSection *visibleSection, NSError *error) {
        if (error) {
            // Reminder: an error is *expected* here when 1st loading an article. This is
            // because 'saveOpenArticleTitleWithCurrentlyOnscreenFragment' is also called
            // by 'viewDidAppear' (so the 'Continue reading' widget is kept up-to-date even
            // when tapping the 'Back' button), but on 1st load the article is not yet
            // fetched when this occurs.
            return;
        }
        NSURL *url = [self.article.url wmf_URLWithFragment:visibleSection.anchor];
        [[NSUserDefaults wmf] wmf_setOpenArticleURL:url];
    }];
}

- (void)webViewController:(WebViewController *)controller didTapEditForSection:(MWKSection *)section {
    [self showEditorForSectionOrTitleDescription:section];
}

- (void)webViewController:(WebViewController *)controller didTapOnLinkForArticleURL:(NSURL *)url {
    [self pushArticleViewControllerWithURL:url animated:YES];
}

- (void)webViewController:(WebViewController *)controller didSelectText:(NSString *)text {
    [self.shareFunnel logHighlight];
}

- (void)webViewController:(WebViewController *)controller didTapShareWithSelectedText:(NSString *)text {
    [self shareAFactWithTextSnippet:text];
}

- (void)updateTableOfContentsHighlightWithScrollView:(UIScrollView *)scrollView {
    self.sectionToRestoreScrollOffset = nil;
    @weakify(self);

    [self.webViewController getCurrentVisibleSectionCompletion:^(MWKSection *_Nullable section, NSError *_Nullable error) {
        @strongify(self);
        if (section) {
            self.currentSection = section;
            [self selectAndScrollToTableOfContentsItemForSection:section animated:YES];
        } else {
            [self.webViewController getCurrentVisibleFooterIndexCompletion:^(NSNumber *_Nullable index, NSError *_Nullable error) {
                @strongify(self);
                if (index) {
                    [self selectAndScrollToTableOfContentsFooterItemAtIndex:index.integerValue animated:YES];
                }
            }];
        }
    }];

    self.previousContentOffsetYForTOCUpdate = scrollView.contentOffset.y;
}

- (void)webViewController:(WebViewController *)controller scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewWillBeginDragging:scrollView];
    [self.readingListHintController scrollViewWillBeginDragging];
}

- (void)webViewController:(WebViewController *)controller scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.isUpdateTableOfContentsSectionOnScrollEnabled && (scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) && ABS(self.previousContentOffsetYForTOCUpdate - scrollView.contentOffset.y) > WMFArticleViewControllerTableOfContentsSectionUpdateScrollDistance) {
        [self updateTableOfContentsHighlightWithScrollView:scrollView];
    }
    [self.navigationBarHider scrollViewDidScroll:scrollView];
}

- (void)webViewController:(WebViewController *)controller scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self.navigationBarHider scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)webViewController:(WebViewController *)controller scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewDidEndDecelerating:scrollView];
}

- (void)webViewController:(WebViewController *)controller scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewDidEndScrollingAnimation:scrollView];
}

- (BOOL)webViewController:(nonnull WebViewController *)controller scrollViewShouldScrollToTop:(nonnull UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewWillScrollToTop:scrollView];
    return YES;
}

- (void)webViewController:(WebViewController *)controller scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if (self.isUpdateTableOfContentsSectionOnScrollEnabled) {
        [self updateTableOfContentsHighlightWithScrollView:scrollView];
    }
    [self.navigationBarHider scrollViewDidScrollToTop:scrollView];
}

#pragma mark - Footer menu

- (void)webViewController:(WebViewController *)controller didTapFooterMenuItem:(WMFArticleFooterMenuItem)item payload:(NSArray *)payload {
    switch (item) {
        case WMFArticleFooterMenuItemLanguages:
            [self showLanguages];
            break;
        case WMFArticleFooterMenuItemLastEdited:
            [self showEditHistory];
            break;
        case WMFArticleFooterMenuItemPageIssues:
            [self showPageIssues:payload];
            break;
        case WMFArticleFooterMenuItemDisambiguation:
            [self showDisambiguationPages:payload];
            break;
        case WMFArticleFooterMenuItemCoordinate:
            [self showLocation];
            break;
        case WMFArticleFooterMenuItemTalkPage:
            [self showTalkPage];
            break;
    }
}

- (void)webViewController:(WebViewController *)controller didTapFooterReadMoreSaveForLaterForArticleURL:(NSURL *)articleURL didSave:(BOOL)didSave {
    [self.readingListHintController didSave:didSave articleURL:articleURL theme:self.theme];
    if (didSave) {
        [[ReadingListsFunnel shared] logArticleSaveInReadMore:articleURL];
    } else {
        [[ReadingListsFunnel shared] logArticleUnsaveInReadMore:articleURL];
    }
}

- (void)webViewController:(WebViewController *)controller didTapAddTitleDescriptionForArticle:(MWKArticle *)article {
    [self showTitleDescriptionEditor];
}

- (void)showLocation {
    NSURL *placesURL = [NSUserActivity wmf_URLForActivityOfType:WMFUserActivityTypePlaces withArticleURL:self.article.url];
    [[UIApplication sharedApplication] openURL:placesURL options:@{} completionHandler:NULL];
}

- (void)presentViewControllerEmbeddedInNavigationController:(UIViewController<WMFThemeable> *)viewController {
    [viewController applyTheme:self.theme];
    WMFThemeableNavigationController *navC = [[WMFThemeableNavigationController alloc] initWithRootViewController:viewController theme:self.theme];
    [self presentViewController:navC animated:YES completion:nil];
}

- (void)showDisambiguationPages:(NSArray<NSURL *> *)pageURLs {
    WMFDisambiguationPagesViewController *articleListVC = [[WMFDisambiguationPagesViewController alloc] initWithURLs:pageURLs siteURL:self.article.url dataStore:self.dataStore theme:self.theme];
    articleListVC.title = WMFLocalizedStringWithDefaultValue(@"page-similar-titles", nil, nil, @"Similar pages", @"Label for button that shows a list of similar titles (disambiguation) for the current page");
    articleListVC.navigationItem.leftBarButtonItem = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(dismissPresentedViewController)];
    [self presentViewControllerEmbeddedInNavigationController:articleListVC];
}

- (void)dismissPresentedViewController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)showEditHistory {
    PageHistoryViewController *editHistoryVC = [PageHistoryViewController wmf_initialViewControllerFromClassStoryboard];
    editHistoryVC.article = self.article;
    [self presentViewControllerEmbeddedInNavigationController:editHistoryVC];
}

- (void)showTalkPage {
    SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:self.articleTalkPageURL];
    [self.navigationController presentViewController:safariController animated:YES completion:nil];
}

- (NSURL *)articleTalkPageURL {
    return [self.articleURL wmf_URLWithTitle:[@"Talk:" stringByAppendingString:self.articleURL.wmf_title]];
}

- (void)showLanguages {
    WMFArticleLanguagesViewController *languagesVC = [WMFArticleLanguagesViewController articleLanguagesViewControllerWithArticleURL:self.article.url];
    languagesVC.delegate = self;
    [self presentViewControllerEmbeddedInNavigationController:languagesVC];
}

- (void)showPageIssues:(NSArray<NSString *> *)issueStrings {
    WMFPageIssuesTableViewController *issuesVC = [[WMFPageIssuesTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    issuesVC.issues = issueStrings;
    [self presentViewControllerEmbeddedInNavigationController:issuesVC];
}

#pragma mark - Header Tap Gesture

- (void)imageViewDidTap:(UITapGestureRecognizer *)tap {
    WMFArticleImageGalleryViewController *fullscreenGallery = [[WMFArticleImageGalleryViewController alloc] initWithArticle:self.article theme:self.theme overlayViewTopBarHidden:NO];
    //    fullscreenGallery.referenceViewDelegate = self;
    if (fullscreenGallery != nil) {
        [self presentViewController:fullscreenGallery animated:YES completion:nil];
    }
}

#pragma mark - WMFImageGalleryViewControllerReferenceViewDelegate

- (nullable UIImageView *)referenceViewForImageController:(WMFArticleImageGalleryViewController *)controller {
    MWKImage *currentImage = [controller currentImage];
    MWKImage *leadImage = self.article.leadImage;
    if ([currentImage isVariantOfImage:leadImage]) {
        return self.headerImageView;
    } else {
        return nil;
    }
}

#pragma mark - Edit Section

- (void)showEditorForSectionOrTitleDescription:(MWKSection *)section {
    if (self.article.editable) {
        if ([self.article isWikidataDescriptionEditable] && [section isLeadSection] && self.article.entityDescription) {
            [self showEditSectionOrTitleDescriptionDialogForSection:section];
        } else {
            [self showEditorForSection:section];
        }
    } else {
        ProtectedEditAttemptFunnel *funnel = [[ProtectedEditAttemptFunnel alloc] init];
        [funnel logProtectionStatus:[[self.article.protection allowedGroupsForAction:@"edit"] componentsJoinedByString:@","]];
        [self showProtectedDialog];
    }
}

- (void)showEditorForSection:(MWKSection *)section {
    SectionEditorViewController *sectionEditVC = [SectionEditorViewController wmf_initialViewControllerFromClassStoryboard];
    sectionEditVC.section = section;
    sectionEditVC.delegate = self;
    [self presentViewControllerEmbeddedInNavigationController:sectionEditVC];
}

- (void)descriptionEditViewControllerEditSucceeded:(DescriptionEditViewController *)descriptionEditViewController {
    [self fetchArticle];
}

- (void)showTitleDescriptionEditor {
    DescriptionEditViewController *editVC = [DescriptionEditViewController wmf_initialViewControllerFromClassStoryboard];
    editVC.delegate = self;
    editVC.article = self.article;
    [editVC applyTheme:self.theme];

    WMFThemeableNavigationController *navVC = [[WMFThemeableNavigationController alloc] initWithRootViewController:editVC theme:self.theme];
    navVC.view.opaque = NO;
    navVC.view.backgroundColor = [UIColor clearColor];
    navVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;

    BOOL needsIntro = ![[NSUserDefaults standardUserDefaults] wmf_didShowTitleDescriptionEditingIntro];
    if (needsIntro) {
        navVC.view.alpha = 0;
    }
    
    @weakify(self);
    @weakify(navVC);
    void (^showIntro)(void)  = ^{
        @strongify(self);
        DescriptionWelcomeInitialViewController *welcomeVC = [DescriptionWelcomeInitialViewController wmf_viewControllerFromDescriptionWelcomeStoryboard];
        [welcomeVC applyTheme:self.theme];
        [navVC presentViewController:welcomeVC animated:YES completion:^{
            @strongify(navVC);
            [[NSUserDefaults standardUserDefaults] wmf_setDidShowTitleDescriptionEditingIntro:YES];
            navVC.view.alpha = 1;
        }];
    };
    
    [self presentViewController:navVC animated:!needsIntro completion:(needsIntro ? showIntro : nil)];
}

- (void)showEditSectionOrTitleDescriptionDialogForSection:(MWKSection *)section {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];

    [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"description-edit-pencil-title", nil, nil, @"Edit title description", @"Title for button used to show title description editor")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *_Nonnull action) {
                                                [self showTitleDescriptionEditor];
                                            }]];

    [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"description-edit-pencil-introduction", nil, nil, @"Edit introduction", @"Title for button used to show article lead section editor")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *_Nonnull action) {
                                                [self showEditorForSection:section];
                                            }]];

    [sheet addAction:[UIAlertAction actionWithTitle:[WMFCommonStrings cancelActionTitle] style:UIAlertActionStyleCancel handler:NULL]];

    [self presentViewController:sheet animated:YES completion:NULL];
}

- (void)showProtectedDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WMFLocalizedStringWithDefaultValue(@"page-protected-can-not-edit-title", nil, nil, @"This page is protected", @"Title of alert dialog shown when trying to edit a page that is protected beyond what the user can edit.") message:WMFLocalizedStringWithDefaultValue(@"page-protected-can-not-edit", nil, nil, @"You do not have the rights to edit this page", @"Text of alert dialog shown when trying to edit a page that is protected beyond what the user can edit.") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"button-ok", nil, nil, @"OK", @"Button text for ok button used in various places\n{{Identical|OK}}") style:UIAlertActionStyleCancel handler:NULL]];
    [self presentViewController:alert animated:YES completion:NULL];
}

#pragma mark - SectionEditorViewControllerDelegate

- (void)sectionEditorFinishedEditing:(SectionEditorViewController *)sectionEditorViewController withChanges:(BOOL)didChange {
    self.skipFetchOnViewDidAppear = YES;
    [self dismissViewControllerAnimated:YES completion:NULL];
    if (didChange) {
        [self fetchArticle];
    }
}

#pragma mark - Article link and image peeking via WKUIDelegate

- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo {
    return elementInfo.linkURL && [elementInfo.linkURL wmf_isPeekable];
}

- (nullable UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id<WKPreviewActionItem>> *)previewActions {
    NSURLComponents *linkURLComponents = [[NSURLComponents alloc] initWithURL:elementInfo.linkURL resolvingAgainstBaseURL:NO];
    NSString *eventLoggingLabel = linkURLComponents.wmf_eventLoggingLabel;
    DDLogDebug(@"Event logging label is %@", eventLoggingLabel);
    if (eventLoggingLabel) {
        self.eventLoggingLabel = eventLoggingLabel;
    } else {
        self.eventLoggingLabel = EventLoggingLabelOutLink;
    }
    NSURLComponents *updatedLinkURLComponents = linkURLComponents.wmf_componentsByRemovingInternalQueryParameters;
    NSURL *updatedLinkURL = updatedLinkURLComponents.URL ?: elementInfo.linkURL;
    UIViewController *peekVC = [self peekViewControllerForURL:updatedLinkURL];
    if (peekVC) {
        [self.webViewController hideFindInPageWithCompletion:nil];

        if ([peekVC isKindOfClass:[WMFArticleViewController class]]) {
            ((WMFArticleViewController *)peekVC).articlePreviewingActionsDelegate = self;
        }

        if ([peekVC conformsToProtocol:@protocol(WMFThemeable)]) {
            [(id<WMFThemeable>)peekVC applyTheme:self.theme];
        }
        return peekVC;
    }
    return nil;
}

- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController {
    [self commitViewController:previewingViewController];
}

#pragma mark - WMFImagePreviewingActionsDelegate

- (void)shareImagePreviewActionSelectedWithImageController:(nonnull WMFImageGalleryViewController *)imageController shareActivityController:(nonnull UIActivityViewController *)shareActivityController {
    [self presentViewController:shareActivityController animated:YES completion:nil];
}

#pragma mark - Article lead image peeking via UIViewControllerPreviewingDelegate

- (nullable UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                       viewControllerForLocation:(CGPoint)location {
    if (previewingContext == self.leadImagePreviewingContext) {
        WMFArticleImageGalleryViewController *fullscreenGallery = [[WMFArticleImageGalleryViewController alloc] initWithArticle:self.article selectedImage:nil theme:self.theme overlayViewTopBarHidden:YES];
        fullscreenGallery.imagePreviewingActionsDelegate = self;
        return fullscreenGallery;
    }
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController *)viewControllerToCommit {
    [self commitViewController:viewControllerToCommit];
}

#pragma mark - Peeking registration

- (void)registerForPreviewingIfAvailable {
    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
        if (self.peekingAllowed) {
            self.webViewController.webView.UIDelegate = self;
            self.webViewController.webView.allowsLinkPreview = YES;
        } else {
            self.webViewController.webView.allowsLinkPreview = NO;
        }
        [self unregisterForPreviewing];
        self.leadImagePreviewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.headerView];
    } else {
        [self unregisterForPreviewing];
    }
}

- (void)unregisterForPreviewing {
    if (self.leadImagePreviewingContext) {
        [self unregisterForPreviewingWithContext:self.leadImagePreviewingContext];
        self.leadImagePreviewingContext = nil;
    }
}

#pragma mark - Peeking helpers

- (NSArray<NSString *> *)peekableImageExtensions {
    return @[@"jpg", @"jpeg", @"gif", @"png", @"svg"];
}

- (nullable UIViewController *)peekViewControllerForURL:(NSURL *)linkURL {
    if ([self.peekableImageExtensions containsObject:[[linkURL pathExtension] lowercaseString]]) {
        return [self viewControllerForImageFilePageURL:linkURL withTopBarHidden:YES];
    } else {
        return [self viewControllerForPreviewURL:linkURL];
    }
}

- (NSURL *)galleryURLFromImageFilePageURL:(NSURL *)imageFilePageURL {
    // Find out if the imageFilePageURL's file is in the gallery array, if so return the
    // actual image url (as opposed to the file page url) from the gallery array.
    NSString *fileName = [imageFilePageURL lastPathComponent];
    if ([fileName hasPrefix:@"File:"]) {
        fileName = [fileName substringFromIndex:5];
    }
    return [[self.article imageURLsForGallery] wmf_match:^BOOL(NSURL *galleryURL) {
        return [WMFParseImageNameFromSourceURL(galleryURL).stringByRemovingPercentEncoding hasSuffix:fileName];
    }];
}

- (nullable UIViewController *)viewControllerForImageFilePageURL:(nullable NSURL *)imageFilePageURL withTopBarHidden:(BOOL)topBarHidden {
    NSURL *galleryURL = [self galleryURLFromImageFilePageURL:imageFilePageURL];

    if (!galleryURL) {
        return nil;
    }
    MWKImage *selectedImage = [[MWKImage alloc] initWithArticle:self.article sourceURL:galleryURL];
    WMFArticleImageGalleryViewController *gallery =
        [[WMFArticleImageGalleryViewController alloc] initWithArticle:self.article
                                                        selectedImage:selectedImage
                                                                theme:self.theme
                                              overlayViewTopBarHidden:topBarHidden];
    gallery.imagePreviewingActionsDelegate = self;
    return gallery;
}

- (nullable UIViewController *)viewControllerForPreviewURL:(NSURL *)url {
    if (url && [url wmf_isPeekable]) {
        if ([url wmf_isWikiResource]) {
            WMFArticleViewController *articleViewController = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore theme:self.theme];
            [articleViewController wmf_addPeekableChildViewControllerFor:url dataStore:self.dataStore theme:self.theme];
            return articleViewController;
        } else {
            return [[SFSafariViewController alloc] initWithURL:url];
        }
    }
    return nil;
}

- (void)commitViewController:(UIViewController *)viewControllerToCommit {
    if ([viewControllerToCommit isKindOfClass:[WMFArticleViewController class]]) {
        // Show unobscured article view controller when peeking through.
        [viewControllerToCommit wmf_removePeekableChildViewControllers];
        [self pushArticleViewController:(WMFArticleViewController *)viewControllerToCommit animated:YES];
    } else {
        if ([viewControllerToCommit isKindOfClass:[WMFImageGalleryViewController class]]) {
            [(WMFImageGalleryViewController *)viewControllerToCommit setOverlayViewTopBarHidden:NO];
        }
        [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

#pragma mark - Article previewing actions (buttons beneath peeked article when you drag peek view up)

- (NSArray<id<UIPreviewActionItem>> *)previewActions {
    UIPreviewAction *readAction =
        [UIPreviewAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"button-read-now", nil, nil, @"Read now", @"Read now button text used in various places.")
                                   style:UIPreviewActionStyleDefault
                                 handler:^(UIPreviewAction *_Nonnull action,
                                           UIViewController *_Nonnull previewViewController) {
                                     NSAssert([previewViewController isKindOfClass:[WMFArticleViewController class]], @"Unexpected view controller type");

                                     [self.articlePreviewingActionsDelegate readMoreArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)previewViewController];
                                 }];

    UIPreviewAction *saveAction =
        [UIPreviewAction actionWithTitle:[self.savedPages isSaved:self.articleURL] ? WMFLocalizedStringWithDefaultValue(@"button-saved-remove", nil, nil, @"Remove from saved", @"Remove from saved button text used in various places.") : [WMFCommonStrings saveTitle]
                                   style:UIPreviewActionStyleDefault
                                 handler:^(UIPreviewAction *_Nonnull action,
                                           UIViewController *_Nonnull previewViewController) {
                                     if ([self.savedPages isSaved:self.articleURL]) {
                                         [self.savedPages removeEntryWithURL:self.articleURL];
                                         UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [WMFCommonStrings accessibilityUnsavedNotification]);
                                         [self.articlePreviewingActionsDelegate saveArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)previewViewController didSave:NO articleURL:self.articleURL];
                                     } else {
                                         [self.savedPages addSavedPageWithURL:self.articleURL];
                                         UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [WMFCommonStrings accessibilitySavedNotification]);
                                         [self.articlePreviewingActionsDelegate saveArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)previewViewController didSave:YES articleURL:self.articleURL];
                                     }
                                 }];

    NSURL *articleURL = self.articleURL;
    __weak id<WMFArticlePreviewingActionsDelegate> weakArticlePreviewingActionsDelegate = self.articlePreviewingActionsDelegate;
    void (^logPreviewSaveIfNeeded)(void) = ^{
        BOOL providesEventValues = [weakArticlePreviewingActionsDelegate conformsToProtocol:@protocol(EventLoggingEventValuesProviding)];
        if (!providesEventValues) {
            return;
        }
        id<EventLoggingEventValuesProviding> eventLoggingValuesProvider = (id<EventLoggingEventValuesProviding>)weakArticlePreviewingActionsDelegate;
        EventLoggingCategory eventLoggingCategory = [eventLoggingValuesProvider eventLoggingCategory];
        EventLoggingLabel eventLoggingLabel = [eventLoggingValuesProvider eventLoggingLabel];
        [[ReadingListsFunnel shared] logSaveWithCategory:eventLoggingCategory label:eventLoggingLabel articleURL:articleURL];
    };

    UIPreviewAction *shareAction =
        [UIPreviewAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"share-custom-menu-item", nil, nil, @"Share...", @"Button label for text selection Share\n{{Identical|Share}}")
                                   style:UIPreviewActionStyleDefault
                                 handler:^(UIPreviewAction *_Nonnull action,
                                           UIViewController *_Nonnull previewViewController) {
                                     UIViewController *presenter = (UIViewController *)self.articlePreviewingActionsDelegate;
                                     UIActivityViewController *shareActivityController = [self.article sharingActivityViewControllerWithTextSnippet:nil fromButton:self.shareToolbarItem shareFunnel:self.shareFunnel customActivity:[self addToReadingListActivityWithPresenter:presenter eventLogAction:logPreviewSaveIfNeeded]];
                                     shareActivityController.excludedActivityTypes = @[UIActivityTypeAddToReadingList];
                                     if (shareActivityController) {
                                         NSAssert([previewViewController isKindOfClass:[WMFArticleViewController class]], @"Unexpected view controller type");
                                         [self.articlePreviewingActionsDelegate shareArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)previewViewController
                                                                                                               shareActivityController:shareActivityController];
                                     }
                                 }];

    WMFArticle *wmfarticle = [self.dataStore fetchArticleWithURL:self.articleURL];
    UIPreviewAction *placeAction = nil;
    if (wmfarticle.location) {
        placeAction =
            [UIPreviewAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"page-location", nil, nil, @"View on a map", @"Label for button used to show an article on the map")
                                       style:UIPreviewActionStyleDefault
                                     handler:^(UIPreviewAction *_Nonnull action, UIViewController *_Nonnull previewViewController) {
                                         NSAssert([previewViewController isKindOfClass:[WMFArticleViewController class]], @"Unexpected view controller type");
                                         [self.articlePreviewingActionsDelegate viewOnMapArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)previewViewController];
                                     }];
    }

    if (placeAction) {
        return @[readAction, saveAction, placeAction, shareAction];
    } else {
        return @[readAction, saveAction, shareAction];
    }
}

#pragma mark - WMFArticlePreviewingActionsDelegate methods

- (void)readMoreArticlePreviewActionSelectedWithArticleController:(UIViewController *)articleController {
    [self commitViewController:articleController];
}

- (void)shareArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)articleController
                                       shareActivityController:(UIActivityViewController *)shareActivityController {
    [self presentViewController:shareActivityController animated:YES completion:NULL];
}

- (void)viewOnMapArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)articleController {
    NSURL *placesURL = [NSUserActivity wmf_URLForActivityOfType:WMFUserActivityTypePlaces withArticleURL:articleController.articleURL];
    [[UIApplication sharedApplication] openURL:placesURL options:@{} completionHandler:NULL];
}

- (void)saveArticlePreviewActionSelectedWithArticleController:(nonnull WMFArticleViewController *)articleController didSave:(BOOL)didSave articleURL:(nonnull NSURL *)articleURL {
    [self.readingListHintController didSave:didSave articleURL:articleURL theme:self.theme];
    if (didSave) {
        [[ReadingListsFunnel shared] logSaveWithCategory:self.eventLoggingCategory label:self.eventLoggingLabel articleURL:articleURL];
    } else {
        [[ReadingListsFunnel shared] logUnsaveWithCategory:self.eventLoggingCategory label:self.eventLoggingLabel articleURL:articleURL];
    }
}

#pragma mark - Article Navigation

- (void)pushArticleViewController:(WMFArticleViewController *)articleViewController animated:(BOOL)animated {
    [self wmf_pushArticleViewController:articleViewController animated:YES];
}

- (void)pushArticleViewControllerWithURL:(NSURL *)url animated:(BOOL)animated {
    WMFArticleViewController *articleViewController =
        [[WMFArticleViewController alloc] initWithArticleURL:url
                                                   dataStore:self.dataStore
                                                       theme:self.theme];
    [self pushArticleViewController:articleViewController animated:animated];
}

#pragma mark - One-time toolbar item popover tips

- (BOOL)shouldShowWIconPopover {
    if (!self.navigationController || self.navigationBar.navigationBarPercentHidden == 1.0 || [[NSUserDefaults standardUserDefaults] wmf_didShowWIconPopover]) {
        return NO;
    } else {
        return YES;
    }
}

- (void)showWIconPopoverIfNecessary {
    if (![self shouldShowWIconPopover]) {
        return;
    }

    [self performSelector:@selector(showWIconPopover) withObject:nil afterDelay:1.0];
}

- (void)cancelWIconPopoverDisplay {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showWIconPopover) object:nil];
}

- (void)showWIconPopover {
    [self wmf_presentDynamicHeightPopoverViewControllerForSourceRect:[self.titleButton convertRect:self.titleButton.bounds toView:self.view]
                                                           withTitle:WMFLocalizedStringWithDefaultValue(@"back-button-popover-title", nil, nil, @"Tap to go back", @"Title for popover explaining the 'W' icon may be tapped to go back.")
                                                             message:WMFLocalizedStringWithDefaultValue(@"original-tab-button-popover-description", nil, nil, @"Tap on the 'W' to return to the tab you started from", @"Description for popover explaining the 'W' icon may be tapped to return to the original tab.")
                                                               width:230.0f
                                                            duration:3.0];
    [[NSUserDefaults standardUserDefaults] wmf_setDidShowWIconPopover:YES];
}

#pragma mark - EventLoggingSearchSourceProviding

- (nonnull NSString *)searchSource {
    return @"article";
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    [super applyTheme:theme];

    self.theme = theme;
    [self.webViewController applyTheme:theme];
    if (self.viewIfLoaded == nil) {
        return;
    }
    [[self wmf_emptyView] applyTheme:self.theme];
    self.headerView.backgroundColor = theme.colors.paperBackground;
    self.view.backgroundColor = theme.colors.paperBackground;
    if (self.headerImageView.image == nil) {
        self.headerImageView.backgroundColor = self.theme.colors.paperBackground;
    }
    self.headerImageView.alpha = theme.imageOpacity;
    [self.tableOfContentsViewController applyTheme:theme];
    [self.readingThemesViewController applyTheme:theme];
    self.tableOfContentsSeparatorView.backgroundColor = theme.colors.baseBackground;
    self.hideTableOfContentsToolbarItem.customView.backgroundColor = theme.colors.midBackground;
    // Popover's arrow has to be updated when a new theme is being applied to readingThemesViewController
    self.readingThemesPopoverPresenter.backgroundColor = theme.colors.popoverBackground;
}

@end

NS_ASSUME_NONNULL_END
