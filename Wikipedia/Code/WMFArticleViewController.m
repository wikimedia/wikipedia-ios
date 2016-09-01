#import "WMFArticleViewController_Private.h"
#import "Wikipedia-Swift.h"

#import "NSUserActivity+WMFExtensions.h"

// Frameworks
#import <Masonry/Masonry.h>
#import "BlocksKit+UIKit.h"

// Controller
#import "UIViewController+WMFStoryboardUtilities.h"
#import "WMFReadMoreViewController.h"
#import "WMFImageGalleryViewController.h"
#import "SectionEditorViewController.h"
#import "WMFArticleFooterMenuViewController.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFLanguagesViewController.h"
#import "MWKLanguageLinkController.h"
#import "WMFShareOptionsController.h"
#import "WMFSaveButtonController.h"
#import "UIViewController+WMFSearch.h"

//Funnel
#import "WMFShareFunnel.h"
#import "ProtectedEditAttemptFunnel.h"
#import "PiwikTracker+WMFExtensions.h"

// Model
#import "MWKDataStore.h"
#import "MWKCitation.h"
#import "MWKSavedPageList.h"
#import "MWKUserDataStore.h"
#import "MWKArticle+WMFSharing.h"
#import "MWKHistoryEntry.h"
#import "MWKHistoryList.h"
#import "MWKProtectionStatus.h"
#import "MWKSectionList.h"
#import "MWKHistoryList.h"
#import "MWKLanguageLink.h"

// Networking
#import "WMFArticleFetcher.h"

// View
#import "UIViewController+WMFEmptyView.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import <TUSafariActivity/TUSafariActivity.h>
#import "WMFArticleTextActivitySource.h"
#import "UIImageView+WMFFaceDetectionBasedOnUIApplicationSharedApplication.h"
#import "UIImageView+WMFPlaceholder.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"

#import "NSString+WMFPageUtilities.h"
#import "UIToolbar+WMFStyling.h"
#import <Tweaks/FBTweakInline.h>
#import "WKWebView+WMFWebViewControllerJavascript.h"
#import "WMFImageInfoController.h"
#import "UIViewController+WMFDynamicHeightPopoverMessage.h"

@import SafariServices;

NS_ASSUME_NONNULL_BEGIN

static const CGFloat WMFArticleViewControllerExpandedTableOfContentsWidthPercentage = 0.33;
static const CGFloat WMFArticleViewControllerTableOfContentsSeparatorWidth = 1;
static const CGFloat WMFArticleViewControllerTableOfContentsSectionUpdateScrollDistance = 10;

@interface WMFArticleViewController () <UINavigationControllerDelegate,
                                        WMFImageGalleryViewControllerReferenceViewDelegate,
                                        SectionEditorViewControllerDelegate,
                                        UIViewControllerPreviewingDelegate,
                                        WMFLanguagesViewControllerDelegate,
                                        WMFArticleListTableViewControllerDelegate,
                                        WMFFontSliderViewControllerDelegate,
                                        UIPopoverPresentationControllerDelegate,
                                        WKUIDelegate>

// Data
@property (nonatomic, strong, readwrite, nullable) MWKArticle *article;

// Children
@property (nonatomic, strong, nullable) WMFTableOfContentsViewController *tableOfContentsViewController;
@property (nonatomic, strong) WebViewController *webViewController;

@property (nonatomic, strong, readwrite) NSURL *articleURL;
@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;

@property (strong, nonatomic, nullable, readwrite) WMFShareFunnel *shareFunnel;
@property (strong, nonatomic, nullable) WMFShareOptionsController *shareOptionsController;
@property (nonatomic, strong) WMFSaveButtonController *saveButtonController;

// Data
@property (nonatomic, strong, readonly) MWKHistoryEntry *historyEntry;
@property (nonatomic, strong, readonly) MWKSavedPageList *savedPages;
@property (nonatomic, strong, readonly) MWKHistoryList *recentPages;

// Fetchers
@property (nonatomic, strong) WMFArticleFetcher *articleFetcher;
@property (nonatomic, strong, nullable) AnyPromise *articleFetcherPromise;
@property (nonatomic, strong, nullable) AFNetworkReachabilityManager *reachabilityManager;

// Children
@property (nonatomic, strong) WMFReadMoreViewController *readMoreListViewController;
@property (nonatomic, strong) WMFArticleFooterMenuViewController *footerMenuViewController;

// Views
@property (nonatomic, strong) UIImageView *headerImageView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong, readwrite) UIBarButtonItem *saveToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *languagesToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *shareToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *fontSizeToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *showTableOfContentsToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *hideTableOfContentsToolbarItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *findInPageToolbarItem;
@property (strong, nonatomic) UIProgressView *progressView;
@property (nonatomic, strong) UIRefreshControl *pullToRefresh;

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

@end

@implementation WMFArticleViewController

+ (void)load {
    [self registerTweak];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithArticleURL:(NSURL *)url
                         dataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(url.wmf_title);
    NSParameterAssert(dataStore);

    self = [super init];
    if (self) {
        self.currentFooterIndex = NSNotFound;
        self.articleURL = url;
        self.dataStore = dataStore;
        self.hidesBottomBarWhenPushed = YES;
        self.reachabilityManager = [AFNetworkReachabilityManager manager];
        [self.reachabilityManager startMonitoring];
    }
    return self;
}

#pragma mark - Accessors

- (WMFArticleFooterMenuViewController *)footerMenuViewController {
    if (!_footerMenuViewController && [self hasAboutThisArticle]) {
        self.footerMenuViewController = [[WMFArticleFooterMenuViewController alloc] initWithArticle:self.article similarPagesListDelegate:self];
    }
    return _footerMenuViewController;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.articleURL];
}

- (void)setArticle:(nullable MWKArticle *)article {
    NSAssert(self.isViewLoaded, @"Expecting article to only be set after the view loads.");
    NSAssert([article.url isEqual:[self.articleURL wmf_URLWithFragment:nil]],
             @"Invalid article set for VC expecting article data for title: %@", self.articleURL);

    _shareFunnel = nil;
    _shareOptionsController = nil;
    [self.articleFetcher cancelFetchForArticleURL:self.articleURL];

    _article = article;

    // always update webVC & headerGallery, even if nil so they are reset if needed
    self.footerMenuViewController.article = _article;
    [self.webViewController setArticle:_article articleURL:self.articleURL];

    if (self.article) {
        if ([self.article.url wmf_isNonStandardURL]) {
            self.headerImageView.image = nil;
        } else {
            [self.headerImageView wmf_setImageWithMetadata:_article.leadImage
                                               detectFaces:YES
                                                   failure:WMFIgnoreErrorHandler
                                                   success:^{
                                                       [self layoutHeaderImageViewForSize:self.view.bounds.size];
                                                   }];
        }
        [self startSignificantlyViewedTimer];
        [self wmf_hideEmptyView];
        [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_articleViewActivityWithArticle:self.article]];
    }

    [self updateToolbar];
    [self setupTableOfContentsViewController];
    [self updateWebviewFootersIfNeeded];
    [self updateTableOfContentsForFootersIfNeeded];
    [self observeArticleUpdates];
}

- (MWKHistoryList *)recentPages {
    return self.dataStore.userDataStore.historyList;
}

- (MWKSavedPageList *)savedPages {
    return self.dataStore.userDataStore.savedPageList;
}

- (MWKHistoryEntry *)historyEntry {
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

- (nullable WMFShareOptionsController *)shareOptionsController {
    NSParameterAssert(self.article);
    if (!self.article) {
        return nil;
    }
    if (!_shareOptionsController) {
        _shareOptionsController = [[WMFShareOptionsController alloc] initWithArticle:self.article
                                                                         shareFunnel:self.shareFunnel];
    }
    return _shareOptionsController;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        UIProgressView *progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        progress.translatesAutoresizingMaskIntoConstraints = NO;
        progress.trackTintColor = [UIColor clearColor];
        progress.tintColor = [UIColor wmf_blueTintColor];
        _progressView = progress;
    }

    return _progressView;
}

- (UIView *)headerView {
    if (!_headerView) {
        // HAX: Only read the scale at setup
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGFloat borderHeight = scale > 1 ? 0.5 : 1;
        CGFloat height = 10;

        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, height)];
        _headerView.backgroundColor = [UIColor wmf_articleBackgroundColor];

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
        _headerImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _headerImageView.userInteractionEnabled = YES;
        _headerImageView.clipsToBounds = YES;
        [_headerImageView wmf_configureWithDefaultPlaceholder];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewDidTap:)];
        [_headerImageView addGestureRecognizer:tap];
    }
    return _headerImageView;
}

- (WMFReadMoreViewController *)readMoreListViewController {
    if (!_readMoreListViewController) {
        _readMoreListViewController = [[WMFReadMoreViewController alloc] initWithURL:self.articleURL
                                                                           dataStore:self.dataStore];
        _readMoreListViewController.delegate = self;
    }
    return _readMoreListViewController;
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
}

- (void)articleUpdatedWithNotification:(NSNotification *)note {
    MWKArticle *article = note.userInfo[MWKArticleKey];
    if ([self.articleURL isEqual:article.url]) {
        self.article = article;
    }
}

- (void)observeArticleUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MWKArticleSavedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(articleUpdatedWithNotification:)
                                                 name:MWKArticleSavedNotification
                                               object:nil];
}

- (void)unobserveArticleUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MWKArticleSavedNotification object:nil];
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

- (BOOL)hasReadMore {
    WMF_TECH_DEBT_TODO(filter articles outside main namespace);
    return self.article && !self.article.isMain;
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
                              self.fontSizeToolbarItem,
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
            [articleToolbarItems insertObject:tocItem atIndex:0];
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
    if (!self.saveButtonController) {
        self.saveButtonController = [[WMFSaveButtonController alloc] initWithBarButtonItem:self.saveToolbarItem savedPageList:self.savedPages url:self.articleURL];
    }

    NSArray<UIBarButtonItem *> *toolbarItems = [self articleToolBarItems];

    if (![self.toolbarItems isEqualToArray:toolbarItems]) {
        // HAX: only update toolbar if # of items has changed, otherwise items will (somehow) get lost
        [self setToolbarItems:toolbarItems animated:YES];
    }
}

- (void)updateToolbarItemEnabledState {
    self.fontSizeToolbarItem.enabled = [self canAdjustText];
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
        _showTableOfContentsToolbarItem.accessibilityLabel = MWLocalizedString(@"table-of-contents-button-label", nil);
        return _showTableOfContentsToolbarItem;
    }
    return _showTableOfContentsToolbarItem;
}

- (UIBarButtonItem *)hideTableOfContentsToolbarItem {
    if (!_hideTableOfContentsToolbarItem) {
        UIImage *closeImage = [UIImage imageNamed:@"toc-close"];
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeButton setImage:closeImage forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(hideTableOfContents:) forControlEvents:UIControlEventTouchUpInside];
        closeButton.frame = (CGRect){.origin = CGPointZero, .size = closeImage.size};
        _hideTableOfContentsToolbarItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        _hideTableOfContentsToolbarItem.accessibilityLabel = MWLocalizedString(@"table-of-contents-button-label", nil);
        return _hideTableOfContentsToolbarItem;
    }
    return _hideTableOfContentsToolbarItem;
}

- (UIBarButtonItem *)saveToolbarItem {
    if (!_saveToolbarItem) {
        _saveToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"save"] style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    return _saveToolbarItem;
}

- (UIBarButtonItem *)fontSizeToolbarItem {
    if (!_fontSizeToolbarItem) {
        @weakify(self);
        _fontSizeToolbarItem = [[UIBarButtonItem alloc] bk_initWithImage:[UIImage imageNamed:@"font-size"]
                                                                   style:UIBarButtonItemStylePlain
                                                                 handler:^(id sender) {
                                                                     @strongify(self);
                                                                     [self showFontSizePopup];
                                                                 }];
    }
    return _fontSizeToolbarItem;
}

- (UIBarButtonItem *)shareToolbarItem {
    if (!_shareToolbarItem) {
        @weakify(self);
        _shareToolbarItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                            handler:^(id sender) {
                                                                                @strongify(self);
                                                                                [self shareArticleWithTextSnippet:nil fromButton:self->_shareToolbarItem];
                                                                            }];
    }
    return _shareToolbarItem;
}

- (UIBarButtonItem *)findInPageToolbarItem {
    if (!_findInPageToolbarItem) {
        @weakify(self);
        _findInPageToolbarItem = [[UIBarButtonItem alloc] bk_initWithImage:[UIImage imageNamed:@"find-in-page"]
                                                                     style:UIBarButtonItemStylePlain

                                                                   handler:^(id sender) {
                                                                       @strongify(self);
                                                                       if ([self canFindInPage]) { // Needed so you can't tap find icon when text size adjuster is onscreen.
                                                                           [self showFindInPage];
                                                                       }
                                                                   }];
        _findInPageToolbarItem.accessibilityLabel = MWLocalizedString(@"find-in-page-button-label", nil);
    }
    return _findInPageToolbarItem;
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
    WMFArticleLanguagesViewController *languagesVC = [WMFArticleLanguagesViewController articleLanguagesViewControllerWithArticleURL:self.articleURL];
    languagesVC.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:nil];
}

- (void)languagesController:(WMFLanguagesViewController *)controller didSelectLanguage:(MWKLanguageLink *)language {
    [[PiwikTracker wmf_configuredInstance] wmf_logActionSwitchLanguageInContext:self contentType:nil];
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 [self pushArticleViewControllerWithURL:language.articleURL contentType:nil animated:YES];
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

    BOOL includeReadMore = [self hasReadMore] && [self.readMoreListViewController hasResults];

    [self appendItemsToTableOfContentsIncludingAboutThisArticle:[self hasAboutThisArticle] includeReadMore:includeReadMore];
}

- (void)updateWebviewFootersIfNeeded {
    if ([self.articleURL wmf_isNonStandardURL]) {
        return;
    }

    NSMutableArray *footerVCs = [NSMutableArray arrayWithCapacity:2];
    [footerVCs wmf_safeAddObject:self.footerMenuViewController];

    /*
       NOTE: only include read more if it has results (don't want an empty section). conditionally fetched in `setArticle:`
     */

    BOOL includeReadMore = [self hasReadMore] && [self.readMoreListViewController hasResults];
    if (includeReadMore) {
        [footerVCs addObject:self.readMoreListViewController];
    }

    [self.webViewController setFooterViewControllers:footerVCs];

    [self updateTableOfContentsDisplayModeWithTraitCollection:self.traitCollection];
}

#pragma mark - Progress

- (void)addProgressView {
    NSAssert(!self.progressView.superview, @"Illegal attempt to re-add progress view.");
    if (self.navigationController.navigationBarHidden) {
        return;
    }
    [self.view addSubview:self.progressView];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressView.superview.mas_top);
        make.left.equalTo(self.progressView.superview.mas_left);
        make.right.equalTo(self.progressView.superview.mas_right);
        make.height.equalTo(@2.0);
    }];
}

- (void)removeProgressView {
    [self.progressView removeFromSuperview];
}

- (void)showProgressViewAnimated:(BOOL)animated {
    self.progressView.progress = 0.05;

    if (!animated) {
        [self _showProgressView];
        return;
    }

    [UIView animateWithDuration:0.25
                     animations:^{
                         [self _showProgressView];
                     }
                     completion:^(BOOL finished){
                     }];
}

- (void)_showProgressView {
    self.progressView.alpha = 1.0;
}

- (void)hideProgressViewAnimated:(BOOL)animated {
    if (!animated) {
        [self _hideProgressView];
        return;
    }

    [UIView animateWithDuration:0.25
                     animations:^{
                         [self _hideProgressView];
                     }
                     completion:nil];
}

- (void)_hideProgressView {
    self.progressView.alpha = 0.0;
}

- (void)updateProgress:(CGFloat)progress animated:(BOOL)animated {
    if (progress < self.progressView.progress) {
        return;
    }
    [self.progressView setProgress:progress animated:animated];

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

#pragma mark - Significantly Viewed Timer

- (void)startSignificantlyViewedTimer {
    if (self.significantlyViewedTimer) {
        return;
    }
    if (!self.article) {
        return;
    }
    MWKHistoryList *historyList = self.dataStore.userDataStore.historyList;
    MWKHistoryEntry *entry = [historyList entryForURL:self.articleURL];
    if (!entry.titleWasSignificantlyViewed) {
        self.significantlyViewedTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 /*FBTweakValue(@"Explore", @"Related items", @"Required viewing time", 30.0)*/ target:self selector:@selector(significantlyViewedTimerFired:) userInfo:nil repeats:NO];
    }
}

- (void)significantlyViewedTimerFired:(NSTimer *)timer {
    [self stopSignificantlyViewedTimer];
    MWKHistoryList *historyList = self.dataStore.userDataStore.historyList;
    [historyList setSignificantlyViewedOnPageInHistoryWithURL:self.articleURL];
}

- (void)stopSignificantlyViewedTimer {
    [self.significantlyViewedTimer invalidate];
    self.significantlyViewedTimer = nil;
}

#pragma mark - Title Button

- (void)setUpTitleBarButton {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b adjustsImageWhenHighlighted];
    UIImage *w = [UIImage imageNamed:@"W"];
    [b setImage:w forState:UIControlStateNormal];
    [b sizeToFit];
    @weakify(self);
    [b bk_addEventHandler:^(id sender) {
        @strongify(self);
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
          forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.titleView = b;
    self.navigationItem.titleView.isAccessibilityElement = YES;
    self.navigationItem.titleView.accessibilityLabel = MWLocalizedString(@"home-button-accessibility-label", nil);
    self.navigationItem.titleView.accessibilityTraits |= UIAccessibilityTraitButton;
}

#pragma mark - ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationController.toolbar wmf_applySolidWhiteBackgroundWithTopShadow];

    [self setUpTitleBarButton];
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.view.backgroundColor = [UIColor whiteColor];

    self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItem];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveWithNotification:) name:UIApplicationWillResignActiveNotification object:nil];

    [self setupWebView];
    [self addProgressView];
    [self hideProgressViewAnimated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateTableOfContentsDisplayModeWithTraitCollection:self.traitCollection];

    BOOL isVisibleInline = [[NSUserDefaults wmf_userDefaults] wmf_isTableOfContentsVisibleInline];

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
    [self.reachabilityManager startMonitoring];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self unregisterForPreviewing];

    [self stopSignificantlyViewedTimer];
    [self saveWebViewScrollOffset];
    [self removeProgressView];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.reachabilityManager stopMonitoring];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self.presentedViewController isKindOfClass:[WMFFontSliderViewController class]]) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    [self registerForPreviewingIfAvailable];
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
        self.tableOfContentsViewController.view.frame = CGRectMake(tocOriginX, origin.y, tocWidth, size.height);
        self.tableOfContentsSeparatorView.frame = CGRectMake(separatorOriginX, origin.y, separatorWidth, size.height);
        self.tableOfContentsViewController.view.alpha = isTOCVisible ? 1 : 0;
        self.tableOfContentsSeparatorView.alpha = isTOCVisible ? 1 : 0;
    }

    CGRect webFrame = CGRectMake(webFrameOriginX, origin.y, webFrameWidth, size.height);
    self.webViewController.view.frame = webFrame;
    switch (self.tableOfContentsDisplayState) {
        case WMFTableOfContentsDisplayStateInlineHidden:
            self.webViewController.contentWidthPercentage = 0.71;
            break;
        case WMFTableOfContentsDisplayStateInlineVisible:
            self.webViewController.contentWidthPercentage = 0.90;
            break;
        default:
            self.webViewController.contentWidthPercentage = 1;
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
    self.headerImageView.frame = CGRectMake(marginWidth, 0, headerViewBounds.size.width - 2 * marginWidth, headerViewBounds.size.height);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutForSize:self.view.bounds.size];
}

- (void)updateTableOfContentsDisplayModeWithTraitCollection:(UITraitCollection *)traitCollection {

    BOOL isCompact = traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    self.tableOfContentsDisplaySide = [[UIApplication sharedApplication] wmf_tocShouldBeOnLeft] ? WMFTableOfContentsDisplaySideLeft : WMFTableOfContentsDisplaySideRight;
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

    self.readMoreListViewController.tableView.separatorStyle = isCompact ? UITableViewCellSeparatorStyleSingleLine : UITableViewCellSeparatorStyleNone;
    self.footerMenuViewController.tableView.separatorStyle = isCompact ? UITableViewCellSeparatorStyleSingleLine : UITableViewCellSeparatorStyleNone;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        [self layoutForSize:size];
    }
                                 completion:NULL];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [self updateTableOfContentsDisplayModeWithTraitCollection:newCollection];
    [self setupTableOfContentsViewController];
}

#pragma mark - Web View Setup

- (void)setupWebView {
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
        UIScrollView *scrollView = self.webViewController.webView.scrollView;
        CGFloat previousOffsetPercentage = scrollView.contentOffset.y / scrollView.contentSize.height;
        UIColor *previousBackgrondColor = scrollView.backgroundColor;
        scrollView.backgroundColor = [UIColor whiteColor];
        [UIView animateWithDuration:0.20
            animations:^{
                [self layoutForSize:self.view.bounds.size];
                if (self.sectionToRestoreScrollOffset) {
                    [self.webViewController scrollToSection:self.currentSection animated:NO];
                } else if (self.footerIndexToRestoreScrollOffset != NSNotFound) {
                    [self.webViewController scrollToFooterAtIndex:self.currentFooterIndex animated:NO];
                } else {
                    scrollView.contentOffset = CGPointMake(0, previousOffsetPercentage * scrollView.contentSize.height);
                }
            }
            completion:^(BOOL finished) {
                scrollView.backgroundColor = previousBackgrondColor;
            }];
    } else {
        [self layoutForSize:self.view.bounds.size];
    }
}

- (void)showTableOfContents:(id)sender {
    if (self.tableOfContentsViewController == nil) {
        return;
    }
    switch (self.tableOfContentsDisplayMode) {
        case WMFTableOfContentsDisplayModeInline:
            if (sender != self) {
                [[NSUserDefaults wmf_userDefaults] wmf_setTableOfContentsIsVisibleInline:YES];
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
                [[NSUserDefaults wmf_userDefaults] wmf_setTableOfContentsIsVisibleInline:NO];
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
                    [self dismissViewControllerAnimated:NO completion:NULL];
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

                if (self.tableOfContentsSeparatorView == nil) {
                    self.tableOfContentsSeparatorView = [[UIView alloc] init];
                    self.tableOfContentsSeparatorView.backgroundColor = [UIColor wmf_lightGrayColor];
                }

                [self createTableOfContentsViewControllerIfNeeded];

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

- (void)fetchArticleForce:(BOOL)force {
    NSAssert([[NSThread currentThread] isMainThread], @"Not on main thread!");
    NSAssert(self.isViewLoaded, @"Should only fetch article when view is loaded so we can update its state.");
    if (!force && self.article) {
        [self.pullToRefresh endRefreshing];
        return;
    }

    //only show a blank view if we have nothing to show
    if (!self.article) {
        [self wmf_showEmptyViewOfType:WMFEmptyViewTypeBlank];
        [self.view bringSubviewToFront:self.progressView];
    }

    [self showProgressViewAnimated:YES];
    [self unobserveArticleUpdates];

    @weakify(self);
    self.articleFetcherPromise = [self.articleFetcher fetchLatestVersionOfArticleWithURL:self.articleURL
                                                                           forceDownload:force
                                                                                progress:^(CGFloat progress) {
                                                                                    [self updateProgress:[self totalProgressWithArticleFetcherProgress:progress] animated:YES];
                                                                                }]
                                     .then(^(MWKArticle *article) {
                                         @strongify(self);
                                         [self.pullToRefresh endRefreshing];
                                         [self updateProgress:[self totalProgressWithArticleFetcherProgress:1.0] animated:YES];
                                         self.article = article;
                                         /*
           NOTE(bgerstle): add side effects to setArticle, not here. this ensures they happen even when falling back to
           cached content
         */
                                     })
                                     .catch(^(NSError *error) {
                                         @strongify(self);
                                         DDLogError(@"Article Fetch Error: %@", [error localizedDescription]);
                                         [self.pullToRefresh endRefreshing];
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
                                         } else {
                                             [self wmf_showEmptyViewOfType:WMFEmptyViewTypeArticleDidNotLoad];
                                             [self.view bringSubviewToFront:self.progressView];
                                             [[WMFAlertManager sharedInstance] showErrorAlert:error
                                                                                       sticky:NO
                                                                        dismissPreviousAlerts:NO
                                                                                  tapCallBack:NULL];

                                             if ([error wmf_isNetworkConnectionError]) {
                                                 @weakify(self);
                                                 [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
                                                     switch (status) {
                                                         case AFNetworkReachabilityStatusReachableViaWWAN:
                                                         case AFNetworkReachabilityStatusReachableViaWiFi: {
                                                             @strongify(self);
                                                             [self fetchArticleIfNeeded];
                                                         } break;
                                                         default:
                                                             break;
                                                     }
                                                 }];
                                             }
                                         }
                                     })
                                     .finally(^{
                                         @strongify(self);
                                         self.articleFetcherPromise = nil;
                                     });
}

- (void)fetchArticle {
    [self fetchArticleForce:YES];
}

- (void)fetchArticleIfNeeded {
    [self fetchArticleForce:NO];
}

- (void)fetchReadMoreIfNeeded {
    if (![self hasReadMore]) {
        return;
    }

    @weakify(self);
    [self.readMoreListViewController fetchIfNeeded].then(^{
                                                       @strongify(self);
                                                       if (!self) {
                                                           return;
                                                       }
                                                       // update footers to include read more if there are results
                                                       [self updateWebviewFootersIfNeeded];
                                                       [self updateTableOfContentsForFootersIfNeeded];
                                                   })
        .catch(^(NSError *error) {
            DDLogError(@"Read More Fetch Error: %@", error);
        WMF_TECH_DEBT_TODO(show read more w / an error view and allow user to retry ? );
        });
}

#pragma mark - Share

- (void)shareAFactWithTextSnippet:(nullable NSString *)text {
    if (self.shareOptionsController.isActive) {
        return;
    }
    [self.shareOptionsController presentShareOptionsWithSnippet:text inViewController:self fromBarButtonItem:self.shareToolbarItem];
}

- (void)shareArticleFromButton:(nullable UIBarButtonItem *)button {
    [self shareArticleWithTextSnippet:nil fromButton:button];
}

- (void)shareArticleWithTextSnippet:(nullable NSString *)text fromButton:(UIBarButtonItem *)button {
    NSParameterAssert(button);
    if (!button) {
        //If we get no button, we will crash below on iPad
        //The assert above shoud help, but lets make sure we bail in prod
        return;
    }
    [self.shareFunnel logShareButtonTappedResultingInSelection:text];

    NSMutableArray *items = [NSMutableArray array];

    [items addObject:[[WMFArticleTextActivitySource alloc] initWithArticle:self.article shareText:text]];

    NSURL *url = [NSURL wmf_desktopURLForURL:self.articleURL];

    if (url) {
        url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@?%@",
                                                                       url.absoluteString, @"wprov=sfsi1"]];

        [items addObject:url];
    }

    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:@[[[TUSafariActivity alloc] init]]];
    UIPopoverPresentationController *presenter = [vc popoverPresentationController];
    presenter.barButtonItem = button;

    [self presentViewController:vc animated:YES completion:NULL];
}

#pragma mark - Find-in-page

- (void)showFindInPage {
    if (self.presentedViewController != nil) {
        return;
    }

    [self.webViewController showFindInPage];
}

#pragma mark - Font Size

- (void)showFontSizePopup {
    NSArray *fontSizes = self.fontSizeMultipliers;
    NSUInteger index = self.indexOfCurrentFontSize;

    WMFFontSliderViewController *vc = [[WMFFontSliderViewController alloc] initWithNibName:@"WMFFontSliderViewController" bundle:nil];
    vc.preferredContentSize = vc.view.frame.size;
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.delegate = self;

    [vc setValuesWithSteps:fontSizes.count current:index];

    UIPopoverPresentationController *presenter = [vc popoverPresentationController];
    presenter.delegate = self;
    presenter.backgroundColor = vc.view.backgroundColor;
    presenter.barButtonItem = self.fontSizeToolbarItem;
    presenter.permittedArrowDirections = UIPopoverArrowDirectionDown;

    [self presentViewController:vc animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (void)sliderValueChangedInController:(WMFFontSliderViewController *)container value:(NSInteger)value {
    NSArray *fontSizes = self.fontSizeMultipliers;

    if (value > fontSizes.count) {
        return;
    }

    [self.webViewController setFontSizeMultiplier:self.fontSizeMultipliers[value]];
}

- (NSArray<NSNumber *> *)fontSizeMultipliers {
    return @[@70, @85, @100, @115, @130, @145, @160];

    //    return @[@(FBTweakValue(@"Article", @"Font Size", @"Step 1", 70)),
    //             @(FBTweakValue(@"Article", @"Font Size", @"Step 2", 85)),
    //             @(FBTweakValue(@"Article", @"Font Size", @"Step 3", 100)),
    //             @(FBTweakValue(@"Article", @"Font Size", @"Step 4", 115)),
    //             @(FBTweakValue(@"Article", @"Font Size", @"Step 5", 130)),
    //             @(FBTweakValue(@"Article", @"Font Size", @"Step 6", 145)),
    //             @(FBTweakValue(@"Article", @"Font Size", @"Step 7", 160))
    //    ];
}

- (NSUInteger)indexOfCurrentFontSize {
    NSNumber *fontSize = [[NSUserDefaults wmf_userDefaults] wmf_readingFontSize];

    NSUInteger index = [[self fontSizeMultipliers] indexOfObject:fontSize];

    if (index == NSNotFound) {
        index = [[[self fontSizeMultipliers] bk_reduce:@(NSIntegerMax)
                                             withBlock:^id(NSNumber *current, NSNumber *obj) {
                                                 NSUInteger currentDistance = current.integerValue;
                                                 NSUInteger objDistance = abs((int)(obj.integerValue - fontSize.integerValue));
                                                 if (objDistance < currentDistance) {
                                                     return obj;
                                                 } else {
                                                     return current;
                                                 }
                                             }] integerValue];
    }

    return index;
}

#pragma mark - WMFWebViewControllerDelegate

- (void)webViewController:(WebViewController *)controller
    didTapImageWithSourceURL:(nonnull NSURL *)imageSourceURL {
    MWKImage *selectedImage = [[MWKImage alloc] initWithArticle:self.article sourceURL:imageSourceURL];
    WMFArticleImageGalleryViewController *fullscreenGallery = [[WMFArticleImageGalleryViewController alloc] initWithArticle:self.article selectedImage:selectedImage];
    if (fullscreenGallery != nil) {
        [self presentViewController:fullscreenGallery animated:YES completion:nil];
    }
}

- (void)webViewController:(WebViewController *)controller didLoadArticle:(MWKArticle *)article {
    [self completeAndHideProgressWithCompletion:^{
        //Without this pause, the motion happens too soon after loading the article
        dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
            [self showTableOfContentsAndFindInPageIconPopoversIfNecessary];
        });
    }];

    if (self.tableOfContentsDisplayMode != WMFTableOfContentsDisplayModeModal) {
        [self setupTableOfContentsViewController];
        [self layoutForSize:self.view.bounds.size];
        [self.tableOfContentsViewController selectAndScrollToItemAtIndex:0 animated:NO];
    }

    [self.delegate articleControllerDidLoadArticle:self];
    [self fetchReadMoreIfNeeded];
}

- (void)webViewController:(WebViewController *)controller didTapEditForSection:(MWKSection *)section {
    [self showEditorForSection:section];
}

- (void)webViewController:(WebViewController *)controller didTapOnLinkForArticleURL:(NSURL *)url {
    [self pushArticleViewControllerWithURL:url contentType:nil animated:YES];
}

- (void)webViewController:(WebViewController *)controller didSelectText:(NSString *)text {
    [self.shareFunnel logHighlight];
}

- (void)webViewController:(WebViewController *)controller didTapShareWithSelectedText:(NSString *)text {
    [self shareAFactWithTextSnippet:text];
}

- (nullable NSString *)webViewController:(WebViewController *)controller titleForFooterViewController:(UIViewController *)footerViewController {
    if (footerViewController == self.readMoreListViewController) {
        return [MWSiteLocalizedString(self.articleURL, @"article-read-more-title", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    } else if (footerViewController == self.footerMenuViewController) {
        return [MWSiteLocalizedString(self.articleURL, @"article-about-title", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    return nil;
}

- (void)updateTableOfContentsHighlightWithScrollView:(UIScrollView *)scrollView {
    self.currentFooterIndex = NSNotFound;
    self.sectionToRestoreScrollOffset = nil;
    self.footerIndexToRestoreScrollOffset = NSNotFound;
    [self.webViewController getCurrentVisibleSectionCompletion:^(MWKSection *_Nullable section, NSError *_Nullable error) {
        if (section) {
            self.currentSection = section;
            self.currentFooterIndex = NSNotFound;
            [self selectAndScrollToTableOfContentsItemForSection:section animated:YES];
        } else {
            NSInteger visibleFooterIndex = self.webViewController.visibleFooterIndex;
            if (visibleFooterIndex != NSNotFound) {
                [self selectAndScrollToTableOfContentsFooterItemAtIndex:visibleFooterIndex animated:YES];
                self.currentFooterIndex = visibleFooterIndex;
                self.currentSection = nil;
            }
        }
    }];

    self.previousContentOffsetYForTOCUpdate = scrollView.contentOffset.y;
}

- (void)webViewController:(WebViewController *)controller scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.isUpdateTableOfContentsSectionOnScrollEnabled && (scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) && ABS(self.previousContentOffsetYForTOCUpdate - scrollView.contentOffset.y) > WMFArticleViewControllerTableOfContentsSectionUpdateScrollDistance) {
        [self updateTableOfContentsHighlightWithScrollView:scrollView];
    }
}

- (void)webViewController:(WebViewController *)controller scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if (self.isUpdateTableOfContentsSectionOnScrollEnabled) {
        [self updateTableOfContentsHighlightWithScrollView:scrollView];
    }
}

#pragma mark - Header Tap Gesture

- (void)imageViewDidTap:(UITapGestureRecognizer *)tap {
    NSAssert(self.article.isCached, @"Expected article data to already be downloaded.");
    if (!self.article.isCached) {
        return;
    }

    WMFArticleImageGalleryViewController *fullscreenGallery = [[WMFArticleImageGalleryViewController alloc] initWithArticle:self.article];
    fullscreenGallery.referenceViewDelegate = self;
    if (fullscreenGallery != nil) {
        [self presentViewController:fullscreenGallery animated:YES completion:nil];
    }
}

#pragma mark - WMFImageGalleryViewControllerReferenceViewDelegate

- (UIImageView *)referenceViewForImageController:(WMFArticleImageGalleryViewController *)controller {
    MWKImage *currentImage = [controller currentImage];
    MWKImage *leadImage = self.article.leadImage;
    if ([currentImage isVariantOfImage:leadImage]) {
        return self.headerImageView;
    } else {
        return nil;
    }
}

#pragma mark - Edit Section

- (void)showEditorForSection:(MWKSection *)section {
    if (self.article.editable) {
        SectionEditorViewController *sectionEditVC = [SectionEditorViewController wmf_initialViewControllerFromClassStoryboard];
        sectionEditVC.section = section;
        sectionEditVC.delegate = self;
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:sectionEditVC];
        [self presentViewController:nc animated:YES completion:NULL];
    } else {
        ProtectedEditAttemptFunnel *funnel = [[ProtectedEditAttemptFunnel alloc] init];
        [funnel logProtectionStatus:[[self.article.protection allowedGroupsForAction:@"edit"] componentsJoinedByString:@","]];
        [self showProtectedDialog];
    }
}

- (void)showProtectedDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:MWLocalizedString(@"page_protected_can_not_edit_title", nil) message:MWLocalizedString(@"page_protected_can_not_edit", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"button-ok", nil) style:UIAlertActionStyleCancel handler:NULL]];
    [self presentViewController:alert animated:YES completion:NULL];
}

#pragma mark - SectionEditorViewControllerDelegate

- (void)sectionEditorFinishedEditing:(SectionEditorViewController *)sectionEditorViewController {
    self.skipFetchOnViewDidAppear = YES;
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self fetchArticle];
}

#pragma mark - Article link and image peeking via WKUIDelegate

- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo {
    return elementInfo.linkURL && [elementInfo.linkURL wmf_isPeekable];
}

- (nullable UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions {
    UIViewController *peekVC = [self peekViewControllerForURL:elementInfo.linkURL];
    if (peekVC) {
        [[PiwikTracker wmf_configuredInstance] wmf_logActionPreviewInContext:self contentType:nil];
        [self.webViewController hideFindInPageWithCompletion:nil];
        
        return peekVC;
    }
    return nil;
}

- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController {
    [self commitViewController:previewingViewController];
}

#pragma mark - Article lead image peeking via UIViewControllerPreviewingDelegate

- (nullable UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                       viewControllerForLocation:(CGPoint)location {
    if (previewingContext == self.leadImagePreviewingContext) {
        [[PiwikTracker wmf_configuredInstance] wmf_logActionPreviewInContext:self contentType:nil];
        WMFArticleImageGalleryViewController *fullscreenGallery = [[WMFArticleImageGalleryViewController alloc] initWithArticle:self.article];
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
    [self wmf_ifForceTouchAvailable:^{
        if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:10]) {
            self.webViewController.webView.UIDelegate = self;
            self.webViewController.webView.allowsLinkPreview = YES;
        }else{
            self.webViewController.webView.allowsLinkPreview = NO;
        }
        [self unregisterForPreviewing];
        self.leadImagePreviewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.webViewController.headerView];
    }
        unavailable:^{
            [self unregisterForPreviewing];
        }];
}

- (void)unregisterForPreviewing {
    if (self.leadImagePreviewingContext) {
        [self unregisterForPreviewingWithContext:self.leadImagePreviewingContext];
        self.leadImagePreviewingContext = nil;
    }
}

#pragma mark - Peeking helpers

- (NSArray<NSString*>*)peekableImageExtensions {
    return @[@"jpg", @"jpeg", @"gif", @"png", @"svg"];
}

- (nullable UIViewController *)peekViewControllerForURL:(NSURL *)linkURL {
    if([self.peekableImageExtensions containsObject:[linkURL pathExtension]]){
        return [self viewControllerForImageFilePageURL:linkURL];
    }else{
        return [self viewControllerForPreviewURL:linkURL];
    }
}

- (NSURL*)galleryURLFromImageFilePageURL:(NSURL*)imageFilePageURL {
    // Find out if the imageFilePageURL's file is in the gallery array, if so return the
    // actual image url (as opposed to the file page url) from the gallery array.
    NSString* fileName = [imageFilePageURL lastPathComponent];
    if([fileName hasPrefix:@"File:"]){
        fileName = [fileName substringFromIndex:5];
    }
    return [[self.article imageURLsForGallery] bk_match:^BOOL(NSURL *galleryURL) {
        return [WMFParseImageNameFromSourceURL(galleryURL).stringByRemovingPercentEncoding hasSuffix:fileName];
    }];
}

- (nullable UIViewController *)viewControllerForImageFilePageURL:(nullable NSURL *)imageFilePageURL {
    NSURL *galleryURL = [self galleryURLFromImageFilePageURL:imageFilePageURL];
    
    if (!galleryURL) {
        return nil;
    }
    MWKImage *selectedImage = [[MWKImage alloc] initWithArticle:self.article sourceURL:galleryURL];
    WMFArticleImageGalleryViewController *gallery =
        [[WMFArticleImageGalleryViewController alloc] initWithArticle:self.article
                                                        selectedImage:selectedImage];
    return gallery;
}

- (UIViewController *)viewControllerForPreviewURL:(NSURL *)url {
    if(url && [url wmf_isPeekable]){
        if ([url wmf_isWikiResource]) {
            return [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore];
        }else{
            return [[SFSafariViewController alloc] initWithURL:url];
        }
    }
    return nil;
}

- (void)commitViewController:(UIViewController *)viewControllerToCommit {
    if ([viewControllerToCommit isKindOfClass:[WMFArticleViewController class]]) {
        [self pushArticleViewController:(WMFArticleViewController *)viewControllerToCommit contentType:nil animated:YES];
    } else {
        [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

#pragma mark - Article Navigation

- (void)pushArticleViewController:(WMFArticleViewController *)articleViewController contentType:(nullable id<WMFAnalyticsContentTypeProviding>)contentType animated:(BOOL)animated {
    [[PiwikTracker wmf_configuredInstance] wmf_logActionTapThroughInContext:self contentType:contentType];
    [self wmf_pushArticleViewController:articleViewController animated:YES];
}

- (void)pushArticleViewControllerWithURL:(NSURL *)url contentType:(nullable id<WMFAnalyticsContentTypeProviding>)contentType animated:(BOOL)animated {
    WMFArticleViewController *articleViewController =
        [[WMFArticleViewController alloc] initWithArticleURL:url
                                                   dataStore:self.dataStore];
    [self pushArticleViewController:articleViewController contentType:contentType animated:animated];
}

#pragma mark - WMFArticleListTableViewControllerDelegate

- (void)listViewController:(WMFArticleListTableViewController *)listController didSelectArticleURL:(NSURL *)url {
    if ([self presentedViewController]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    id<WMFAnalyticsContentTypeProviding> contentType = nil;
    if ([listController conformsToProtocol:@protocol(WMFAnalyticsContentTypeProviding)]) {
        contentType = (id<WMFAnalyticsContentTypeProviding>)listController;
    }
    [self pushArticleViewControllerWithURL:url contentType:contentType animated:YES];
}

- (UIViewController *)listViewController:(WMFArticleListTableViewController *)listController viewControllerForPreviewingArticleURL:(NSURL *)url {
    return [[WMFArticleViewController alloc] initWithArticleURL:url
                                                      dataStore:self.dataStore];
}

- (void)listViewController:(WMFArticleListTableViewController *)listController didCommitToPreviewedViewController:(UIViewController *)viewController {
    if ([self presentedViewController]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    if ([viewController isKindOfClass:[WMFArticleViewController class]]) {
        id<WMFAnalyticsContentTypeProviding> contentType = nil;
        if ([listController conformsToProtocol:@protocol(WMFAnalyticsContentTypeProviding)]) {
            contentType = (id<WMFAnalyticsContentTypeProviding>)listController;
        }
        [self pushArticleViewController:(WMFArticleViewController *)viewController contentType:contentType animated:YES];
    } else {
        [self presentViewController:viewController animated:YES completion:nil];
    }
}

#pragma mark - WMFAnalyticsContextProviding

- (NSString *)analyticsContext {
    return @"Article";
}

- (NSString *)analyticsName {
    return self.articleURL.host;
}

#pragma mark - One-time toolbar item popover tips

- (BOOL)shouldShowTableOfContentsAndFindInPageIconPopovers {
    if (!self.navigationController || [[NSUserDefaults standardUserDefaults] wmf_didShowTableOfContentsAndFindInPageIconPopovers]) {
        return NO;
    } else {
        return YES;
    }
}

- (void)showTableOfContentsAndFindInPageIconPopoversIfNecessary {
    if (![self shouldShowTableOfContentsAndFindInPageIconPopovers]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] wmf_setDidShowTableOfContentsAndFindInPageIconPopovers:YES];

    dispatchOnMainQueueAfterDelayInSeconds(1.0, ^{
        [self wmf_presentDynamicHeightPopoverViewControllerForBarButtonItem:[self tableOfContentsToolbarItem]
                                                                  withTitle:MWLocalizedString(@"table-of-contents-button-label", nil)
                                                                    message:MWLocalizedString(@"table-of-contents-popover-description", nil)
                                                                      width:230.0f];
    });

    dispatchOnMainQueueAfterDelayInSeconds(4.0, ^{
        [self dismissViewControllerAnimated:YES
                                 completion:^{
                                     dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
                                         [self wmf_presentDynamicHeightPopoverViewControllerForBarButtonItem:self.findInPageToolbarItem
                                                                                                   withTitle:MWLocalizedString(@"find-in-page-button-label", nil)
                                                                                                     message:MWLocalizedString(@"find-in-page-popover-description", nil)
                                                                                                       width:230.0f];
                                     });
                                 }];
    });

    dispatchOnMainQueueAfterDelayInSeconds(7.5, ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

@end

NS_ASSUME_NONNULL_END
