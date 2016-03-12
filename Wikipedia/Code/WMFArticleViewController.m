#import "WMFArticleViewController_Private.h"
#import "Wikipedia-Swift.h"

#import "NSUserActivity+WMFExtensions.h"

// Frameworks
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit+UIKit.h>

// Controller
#import "WebViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "WMFArticleHeaderImageGalleryViewController.h"
#import "WMFReadMoreViewController.h"
#import "WMFModalImageGalleryViewController.h"
#import "SectionEditorViewController.h"
#import "WMFArticleFooterMenuViewController.h"
#import "WMFArticleBrowserViewController.h"
#import "LanguagesViewController.h"
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
#import "MWKTitle.h"
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
#import "UIWebView+WMFTrackingView.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import <TUSafariActivity/TUSafariActivity.h>
#import "WMFArticleTextActivitySource.h"

#import "NSString+WMFPageUtilities.h"
#import "NSURL+WMFLinkParsing.h"
#import "NSURL+WMFExtras.h"
#import "UIToolbar+WMFStyling.h"

@import SafariServices;

@import JavaScriptCore;

@import Tweaks;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleViewController ()
<WMFWebViewControllerDelegate,
 UINavigationControllerDelegate,
 WMFArticleHeaderImageGalleryViewControllerDelegate,
 WMFImageGalleryViewControllerDelegate,
 SectionEditorViewControllerDelegate,
 UIViewControllerPreviewingDelegate,
 LanguageSelectionDelegate,
 WMFArticleListTableViewControllerDelegate>

@property (nonatomic, strong, readwrite) MWKTitle* articleTitle;
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;

@property (strong, nonatomic, nullable, readwrite) WMFShareFunnel* shareFunnel;
@property (strong, nonatomic, nullable) WMFShareOptionsController* shareOptionsController;
@property (nonatomic, strong) WMFSaveButtonController* saveButtonController;

// Data
@property (nonatomic, strong, readonly) MWKHistoryEntry* historyEntry;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readonly) MWKHistoryList* recentPages;

// Fetchers
@property (nonatomic, strong) WMFArticleFetcher* articleFetcher;
@property (nonatomic, strong, nullable) AnyPromise* articleFetcherPromise;

// Children
@property (nonatomic, strong) WMFArticleHeaderImageGalleryViewController* headerGallery;
@property (nonatomic, strong) WMFReadMoreViewController* readMoreListViewController;
@property (nonatomic, strong) WMFArticleFooterMenuViewController* footerMenuViewController;

// Views
@property (nonatomic, strong) MASConstraint* headerHeightConstraint;
@property (nonatomic, strong) UIBarButtonItem* saveToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* languagesToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* shareToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* tableOfContentsToolbarItem;
@property (strong, nonatomic) UIProgressView* progressView;
@property (nonatomic, strong) UIRefreshControl* pullToRefresh;

// Previewing
@property (nonatomic, weak) id<UIViewControllerPreviewing> linkPreviewingContext;
@property (nonatomic, assign) BOOL isPreviewing;

@property (strong, nonatomic, nullable) NSTimer* significantlyViewedTimer;

@end

@implementation WMFArticleViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);

    self = [super init];
    if (self) {
        self.articleTitle             = title;
        self.dataStore                = dataStore;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

#pragma mark - Accessors

- (WMFArticleFooterMenuViewController*)footerMenuViewController {
    if (!_footerMenuViewController && [self hasAboutThisArticle]) {
        self.footerMenuViewController = [[WMFArticleFooterMenuViewController alloc] initWithArticle:self.article similarPagesListDelegate:self];
    }
    return _footerMenuViewController;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.articleTitle];
}

- (void)setArticle:(nullable MWKArticle*)article {
    NSAssert(self.isViewLoaded, @"Expecting article to only be set after the view loads.");
    NSAssert([article.title isEqualToTitle:self.articleTitle],
             @"Invalid article set for VC expecting article data for title: %@", self.articleTitle);

    _shareFunnel            = nil;
    _shareOptionsController = nil;
    [self.articleFetcher cancelFetchForPageTitle:_articleTitle];

    _article = article;

    // always update webVC & headerGallery, even if nil so they are reset if needed
    self.footerMenuViewController.article = _article;
    self.webViewController.article        = _article;
    [self.headerGallery showImagesInArticle:_article];

    if (self.article) {
        [self startSignificantlyViewedTimer];
        [self wmf_hideEmptyView];
        [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_articleViewActivityWithArticle:self.article]];
    }

    [self updateToolbar];
    [self createTableOfContentsViewControllerIfNeeded];
    [self fetchReadMoreIfNeeded];
    [self updateWebviewFootersIfNeeded];
    [self observeArticleUpdates];
}

- (MWKHistoryList*)recentPages {
    return self.dataStore.userDataStore.historyList;
}

- (MWKSavedPageList*)savedPages {
    return self.dataStore.userDataStore.savedPageList;
}

- (MWKHistoryEntry*)historyEntry {
    return [self.recentPages entryForTitle:self.articleTitle];
}

- (nullable WMFShareFunnel*)shareFunnel {
    NSParameterAssert(self.article);
    if (!self.article) {
        return nil;
    }
    if (!_shareFunnel) {
        _shareFunnel = [[WMFShareFunnel alloc] initWithArticle:self.article];
    }
    return _shareFunnel;
}

- (nullable WMFShareOptionsController*)shareOptionsController {
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

- (UIProgressView*)progressView {
    if (!_progressView) {
        UIProgressView* progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        progress.translatesAutoresizingMaskIntoConstraints = NO;
        progress.trackTintColor                            = [UIColor clearColor];
        progress.tintColor                                 = [UIColor wmf_blueTintColor];
        _progressView                                      = progress;
    }

    return _progressView;
}

- (WMFReadMoreViewController*)readMoreListViewController {
    if (!_readMoreListViewController) {
        _readMoreListViewController = [[WMFReadMoreViewController alloc] initWithTitle:self.articleTitle
                                                                             dataStore:self.dataStore];
        _readMoreListViewController.delegate = self;
    }
    return _readMoreListViewController;
}

- (WMFArticleFetcher*)articleFetcher {
    if (!_articleFetcher) {
        _articleFetcher = [[WMFArticleFetcher alloc] initWithDataStore:self.dataStore];
    }
    return _articleFetcher;
}

- (WebViewController*)webViewController {
    if (!_webViewController) {
        _webViewController                      = [WebViewController wmf_initialViewControllerFromClassStoryboard];
        _webViewController.delegate             = self;
        _webViewController.headerViewController = self.headerGallery;
    }
    return _webViewController;
}

- (WMFArticleHeaderImageGalleryViewController*)headerGallery {
    if (!_headerGallery) {
        _headerGallery          = [[WMFArticleHeaderImageGalleryViewController alloc] init];
        _headerGallery.delegate = self;
    }
    return _headerGallery;
}

#pragma mark - Notifications and Observations

- (void)applicationWillResignActiveWithNotification:(NSNotification*)note {
    [self saveWebViewScrollOffset];
}

- (void)articleUpdatedWithNotification:(NSNotification*)note {
    MWKArticle* article = note.userInfo[MWKArticleKey];
    if ([self.articleTitle isEqualToTitle:article.title]) {
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

- (BOOL)hasLanguages {
    return self.article.languagecount > 1;
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

- (NSString*)shareText {
    NSString* text = [self.webViewController selectedText];
    if (text.length == 0) {
        text = [self.article shareSnippet];
    }
    return text;
}

#pragma mark - Toolbar Setup

- (void)updateToolbar {
    [self updateToolbarItemsIfNeeded];
    [self updateToolbarItemEnabledState];
}

- (void)updateToolbarItemsIfNeeded {
    if (!self.saveButtonController) {
        self.saveButtonController = [[WMFSaveButtonController alloc] initWithBarButtonItem:self.saveToolbarItem savedPageList:self.savedPages title:self.articleTitle];
    }

    NSArray<UIBarButtonItem*>* toolbarItems =
        [NSArray arrayWithObjects:
         self.languagesToolbarItem,
         [self flexibleSpaceToolbarItem],
         self.shareToolbarItem, [UIBarButtonItem wmf_barButtonItemOfFixedWidth:24.f],
         self.saveToolbarItem, [UIBarButtonItem wmf_barButtonItemOfFixedWidth:2.0],
         [self flexibleSpaceToolbarItem],
         self.tableOfContentsToolbarItem,
         nil];

    if (self.toolbarItems.count != toolbarItems.count) {
        // HAX: only update toolbar if # of items has changed, otherwise items will (somehow) get lost
        [self setToolbarItems:toolbarItems animated:YES];
    }
}

- (void)updateToolbarItemEnabledState {
    self.shareToolbarItem.enabled           = [self canShare];
    self.languagesToolbarItem.enabled       = [self hasLanguages];
    self.tableOfContentsToolbarItem.enabled = [self hasTableOfContents];
}

#pragma mark - Toolbar Items

- (UIBarButtonItem*)tableOfContentsToolbarItem {
    if (!_tableOfContentsToolbarItem) {
        _tableOfContentsToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toc"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(showTableOfContents)];
        _tableOfContentsToolbarItem.accessibilityLabel = MWLocalizedString(@"table-of-contents-button-label", nil);
        return _tableOfContentsToolbarItem;
    }
    return _tableOfContentsToolbarItem;
}

- (UIBarButtonItem*)saveToolbarItem {
    if (!_saveToolbarItem) {
        _saveToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"save"] style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    return _saveToolbarItem;
}

- (UIBarButtonItem*)flexibleSpaceToolbarItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                         target:nil
                                                         action:NULL];
}

- (UIBarButtonItem*)shareToolbarItem {
    if (!_shareToolbarItem) {
        @weakify(self);
        _shareToolbarItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                            handler:^(id sender){
            @strongify(self);
            [self shareArticleWithTextSnippet:nil fromButton:self->_shareToolbarItem];                                                                                
        }];
    }
    return _shareToolbarItem;
}

- (UIBarButtonItem*)languagesToolbarItem {
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
    LanguagesViewController* languagesVC = [LanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    languagesVC.articleTitle              = self.articleTitle;
    languagesVC.languageSelectionDelegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:nil];
}

- (void)languagesController:(LanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language {
    [[PiwikTracker wmf_configuredInstance] wmf_logActionSwitchLanguageInContext:self contentType:nil];
    [[MWKLanguageLinkController sharedInstance] addPreferredLanguage:language];
    [self dismissViewControllerAnimated:YES completion:^{
        [self pushArticleViewControllerWithTitle:language.title contentType:nil animated:YES];
    }];
}

#pragma mark - Article Footers

- (void)updateWebviewFootersIfNeeded {
    NSMutableArray* footerVCs = [NSMutableArray arrayWithCapacity:2];
    [footerVCs wmf_safeAddObject:self.footerMenuViewController];
    /*
       NOTE: only include read more if it has results (don't want an empty section). conditionally fetched in `setArticle:`
     */
    if ([self hasReadMore] && [self.readMoreListViewController hasResults]) {
        [footerVCs addObject:self.readMoreListViewController];
        [self appendReadMoreTableOfContentsItemIfNeeded];
    }
    [self.webViewController setFooterViewControllers:footerVCs];
}

#pragma mark - Progress

- (void)addProgressView {
    NSAssert(!self.progressView.superview, @"Illegal attempt to re-add progress view.");
    if (self.navigationController.navigationBarHidden) {
        return;
    }
    [self.view addSubview:self.progressView];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker* make) {
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

    [UIView animateWithDuration:0.25 animations:^{
        [self _showProgressView];
    } completion:^(BOOL finished) {
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

    [UIView animateWithDuration:0.25 animations:^{
        [self _hideProgressView];
    } completion:nil];
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

- (void)completeAndHideProgress {
    [self updateProgress:1.0 animated:YES];
    dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
        [self hideProgressViewAnimated:YES];
    });
}

/**
 *  Some of the progress is in loading the HTML into the webview
 *  This leaves 20% of progress for that work.
 */
- (CGFloat)totalProgressWithArticleFetcherProgress:(CGFloat)progress {
    return 0.8 * progress;
}

#pragma mark - Significantly Viewed Timer

- (void)startSignificantlyViewedTimer {
    if (self.significantlyViewedTimer) {
        return;
    }
    if (!self.article) {
        return;
    }
    MWKHistoryList* historyList = self.dataStore.userDataStore.historyList;
    MWKHistoryEntry* entry      = [historyList entryForTitle:self.articleTitle];
    if (!entry.titleWasSignificantlyViewed) {
        self.significantlyViewedTimer = [NSTimer scheduledTimerWithTimeInterval:FBTweakValue(@"Explore", @"Related items", @"Required viewing time", 30.0) target:self selector:@selector(significantlyViewedTimerFired:) userInfo:nil repeats:NO];
    }
}

- (void)significantlyViewedTimerFired:(NSTimer*)timer {
    [self stopSignificantlyViewedTimer];
    MWKHistoryList* historyList = self.dataStore.userDataStore.historyList;
    [historyList setSignificantlyViewedOnPageInHistoryWithTitle:self.articleTitle];
    [historyList save];
}

- (void)stopSignificantlyViewedTimer {
    [self.significantlyViewedTimer invalidate];
    self.significantlyViewedTimer = nil;
}

#pragma mark - Title Button

- (void)setUpTitleBarButton {
    UIButton* b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b adjustsImageWhenHighlighted];
    UIImage* w = [UIImage imageNamed:@"W"];
    [b setImage:w forState:UIControlStateNormal];
    [b sizeToFit];
    @weakify(self);
    [b bk_addEventHandler:^(id sender) {
        @strongify(self);
        [self.navigationController popToRootViewControllerAnimated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.titleView                        = b;
    self.navigationItem.titleView.isAccessibilityElement = YES;
    self.navigationItem.titleView.accessibilityLabel     = MWLocalizedString(@"home-button-accessibility-label", nil);
    self.navigationItem.titleView.accessibilityTraits   |= UIAccessibilityTraitButton;
}

#pragma mark - ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.toolbar wmf_applySolidWhiteBackgroundWithTopShadow];

    [self updateToolbar];

    [self setUpTitleBarButton];
    self.view.clipsToBounds                   = NO;
    self.automaticallyAdjustsScrollViewInsets = YES;

    self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItem];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveWithNotification:) name:UIApplicationWillResignActiveNotification object:nil];

    [self setupWebView];
    [self addProgressView];
    [self hideProgressViewAnimated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForPreviewingIfAvailable];
    [self fetchArticleIfNeeded];

    [self startSignificantlyViewedTimer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSUserDefaults standardUserDefaults] wmf_setOpenArticleTitle:self.articleTitle];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self stopSignificantlyViewedTimer];
    [self saveWebViewScrollOffset];
    [self removeProgressView];
    if ([[[NSUserDefaults standardUserDefaults] wmf_openArticleTitle] isEqualToTitle:self.articleTitle]) {
        [[NSUserDefaults standardUserDefaults] wmf_setOpenArticleTitle:nil];
    }
}

- (void)traitCollectionDidChange:(nullable UITraitCollection*)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self registerForPreviewingIfAvailable];
}

#pragma mark - Web View Setup

- (void)setupWebView {
    [self addChildViewController:self.webViewController];
    [self.view addSubview:self.webViewController.view];
    [self.webViewController.view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.leading.trailing.top.and.bottom.equalTo(self.view);
    }];
    [self.webViewController didMoveToParentViewController:self];

    self.pullToRefresh         = [[UIRefreshControl alloc] init];
    self.pullToRefresh.enabled = [self canRefresh];
    [self.pullToRefresh addTarget:self action:@selector(fetchArticle) forControlEvents:UIControlEventValueChanged];
    [self.webViewController.webView.scrollView addSubview:_pullToRefresh];
}

#pragma mark - Save Offset

- (void)saveWebViewScrollOffset {
    // Don't record scroll position of "main" pages.
    if (self.article.isMain) {
        return;
    }
    CGFloat offset = [self.webViewController currentVerticalOffset];
    if (offset > 0) {
        [self.recentPages setPageScrollPosition:offset onPageInHistoryWithTitle:self.articleTitle];
        [self.recentPages save];
    }
}

#pragma mark - Article Fetching

- (void)fetchArticleForce:(BOOL)force {
    NSAssert(self.isViewLoaded, @"Should only fetch article when view is loaded so we can update its state.");
    if (!force && self.article) {
        return;
    }

    //only show a blank view if we have nothing to show
    if (!self.article) {
        [self wmf_showEmptyViewOfType:WMFEmptyViewTypeBlank];
    }

    [self showProgressViewAnimated:YES];
    [self unobserveArticleUpdates];

    @weakify(self);
    self.articleFetcherPromise = [self.articleFetcher fetchLatestVersionOfTitleIfNeeded:self.articleTitle progress:^(CGFloat progress) {
        [self updateProgress:[self totalProgressWithArticleFetcherProgress:progress] animated:YES];
    }].then(^(MWKArticle* article) {
        @strongify(self);
        [self updateProgress:[self totalProgressWithArticleFetcherProgress:1.0] animated:YES];
        self.article = article;
        /*
           NOTE(bgerstle): add side effects to setArticle, not here. this ensures they happen even when falling back to
           cached content
         */
    }).catch(^(NSError* error){
        @strongify(self);
        DDLogError(@"Article Fetch Error: %@", [error localizedDescription]);
        [self hideProgressViewAnimated:YES];
        [self.delegate articleControllerDidLoadArticle:self];

        MWKArticle* cachedFallback = error.userInfo[WMFArticleFetcherErrorCachedFallbackArticleKey];
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
            [[WMFAlertManager sharedInstance] showErrorAlert:error
                                                      sticky:NO
                                       dismissPreviousAlerts:NO
                                                 tapCallBack:NULL];

            if ([error wmf_isNetworkConnectionError]) {
                @weakify(self);
                SCNetworkReachability().then(^{
                    @strongify(self);
                    [self fetchArticleIfNeeded];
                });
            }
        }
    }).finally(^{
        @strongify(self);
        self.articleFetcherPromise = nil;
    });
}

- (void)fetchArticle {
    [self fetchArticleForce:YES];
    [self.pullToRefresh endRefreshing];
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
        // update footers to include read more if there are results
        [self updateWebviewFootersIfNeeded];
    })
    .catch(^(NSError* error){
        DDLogError(@"Read More Fetch Error: %@", error);
        WMF_TECH_DEBT_TODO(show read more w / an error view and allow user to retry ? );
    });
}

#pragma mark - Share

- (void)shareAFactWithTextSnippet : (nullable NSString*)text {
    if (self.shareOptionsController.isActive) {
        return;
    }
    [self.shareOptionsController presentShareOptionsWithSnippet:text inViewController:self fromBarButtonItem:self.shareToolbarItem];
}

- (void)shareArticleFromButton:(nullable UIBarButtonItem*)button {
    [self shareArticleWithTextSnippet:nil fromButton:button];
}

- (void)shareArticleWithTextSnippet:(nullable NSString*)text fromButton:(UIBarButtonItem*)button {
    NSParameterAssert(button);
    if(!button){
        //If we get no button, we will crash below on iPad
        //The assert above shoud help, but lets make sure we bail in prod
        return;
    }
    [self.shareFunnel logShareButtonTappedResultingInSelection:text];

    NSMutableArray* items = [NSMutableArray array];

    [items addObject:[[WMFArticleTextActivitySource alloc] initWithArticle:self.article shareText:text]];

    if (self.article.title.desktopURL) {
        NSURL* url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@?%@",
                                                    self.article.title.desktopURL.absoluteString,
                                                    @"wprov=sfsi1"]];

        [items addObject:url];
    }

    UIActivityViewController* vc               = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:@[[[TUSafariActivity alloc] init]]];
    UIPopoverPresentationController* presenter = [vc popoverPresentationController];
    presenter.barButtonItem = button;

    [self presentViewController:vc animated:YES completion:NULL];
}

#pragma mark - Scroll Position and Fragments

- (void)scrollWebViewToRequestedPosition {
    if (self.articleTitle.fragment) {
        [self.webViewController scrollToFragment:self.articleTitle.fragment];
    } else if (self.restoreScrollPositionOnArticleLoad && self.historyEntry.scrollPosition > 0) {
        self.restoreScrollPositionOnArticleLoad = NO;
        [self.webViewController scrollToVerticalOffset:self.historyEntry.scrollPosition];
    }
    [self markFragmentAsProcessed];
}

- (void)markFragmentAsProcessed {
    //Create a title without the fragment so it wont be followed anymore
    self.articleTitle = [[MWKTitle alloc] initWithSite:self.articleTitle.site normalizedTitle:self.articleTitle.text fragment:nil];
}

#pragma mark - WebView Transition

- (void)showWebViewAtFragment:(NSString*)fragment animated:(BOOL)animated {
    [self.webViewController scrollToFragment:fragment];
}

#pragma mark - WMFWebViewControllerDelegate

- (void)         webViewController:(WebViewController*)controller
    didTapImageWithSourceURLString:(nonnull NSString*)imageSourceURLString {
    MWKImage* selectedImage = [[MWKImage alloc] initWithArticle:self.article sourceURLString:imageSourceURLString];
    /*
       NOTE(bgerstle): not setting gallery delegate intentionally to prevent header gallery changes as a result of
       fullscreen gallery interactions that originate from the webview
     */
    WMFModalImageGalleryViewController* fullscreenGallery =
        [[WMFModalImageGalleryViewController alloc] initWithImagesInArticle:self.article
                                                               currentImage:selectedImage];
    [self presentViewController:fullscreenGallery animated:YES completion:nil];
}

- (void)webViewController:(WebViewController*)controller didLoadArticle:(MWKArticle*)article {
    [self completeAndHideProgress];
    [self scrollWebViewToRequestedPosition];
    [self.delegate articleControllerDidLoadArticle:self];
}

- (void)webViewController:(WebViewController*)controller didTapEditForSection:(MWKSection*)section {
    [self showEditorForSection:section];
}

- (void)webViewController:(WebViewController*)controller didTapOnLinkForTitle:(MWKTitle*)title {
    [self pushArticleViewControllerWithTitle:title contentType:nil animated:YES];
}

- (void)webViewController:(WebViewController*)controller didSelectText:(NSString*)text {
    [self.shareFunnel logHighlight];
}

- (void)webViewController:(WebViewController*)controller didTapShareWithSelectedText:(NSString*)text {
    [self shareAFactWithTextSnippet:text];
}

- (nullable NSString*)webViewController:(WebViewController*)controller titleForFooterViewController:(UIViewController*)footerViewController {
    if (footerViewController == self.readMoreListViewController) {
        return [MWSiteLocalizedString(self.articleTitle.site, @"article-read-more-title", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    } else if (footerViewController == self.footerMenuViewController) {
        return [MWSiteLocalizedString(self.articleTitle.site, @"article-about-title", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    return nil;
}

#pragma mark - WMFArticleHeadermageGalleryViewControllerDelegate

- (void)headerImageGallery:(WMFArticleHeaderImageGalleryViewController* __nonnull)gallery
     didSelectImageAtIndex:(NSUInteger)index {
    WMFModalImageGalleryViewController* fullscreenGallery;

    NSAssert(self.article.isCached, @"Expected article data to already be downloaded.");
    if (!self.article.isCached) {
        return;
    }
    fullscreenGallery = [[WMFModalImageGalleryViewController alloc] initWithImagesInArticle:self.article currentImage:nil];
    fullscreenGallery.currentPage = gallery.currentPage;
    // set delegate to ensure the header gallery is updated when the fullscreen gallery is dismissed
    fullscreenGallery.delegate = self;

    [self presentViewController:fullscreenGallery animated:YES completion:nil];
}

#pragma mark - WMFModalArticleImageGalleryViewControllerDelegate

- (void)willDismissGalleryController:(WMFModalImageGalleryViewController* __nonnull)gallery {
    self.headerGallery.currentPage = gallery.currentPage;
}

#pragma mark - Edit Section

- (void)showEditorForSection:(MWKSection*)section {
    if (self.article.editable) {
        SectionEditorViewController* sectionEditVC = [SectionEditorViewController wmf_initialViewControllerFromClassStoryboard];
        sectionEditVC.section  = section;
        sectionEditVC.delegate = self;
        UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:sectionEditVC];
        [self presentViewController:nc animated:YES completion:NULL];
    } else {
        ProtectedEditAttemptFunnel* funnel = [[ProtectedEditAttemptFunnel alloc] init];
        [funnel logProtectionStatus:[[self.article.protection allowedGroupsForAction:@"edit"] componentsJoinedByString:@","]];
        [self showProtectedDialog];
    }
}

- (void)showProtectedDialog {
    UIAlertView* alert = [[UIAlertView alloc] init];
    alert.title   = MWLocalizedString(@"page_protected_can_not_edit_title", nil);
    alert.message = MWLocalizedString(@"page_protected_can_not_edit", nil);
    [alert addButtonWithTitle:@"OK"];
    alert.cancelButtonIndex = 0;
    [alert show];
}

#pragma mark - SectionEditorViewControllerDelegate

- (void)sectionEditorFinishedEditing:(SectionEditorViewController*)sectionEditorViewController {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self fetchArticle];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (void)registerForPreviewingIfAvailable {
    [self wmf_ifForceTouchAvailable:^{
        [self unregisterForPreviewing];
        UIView* previewView = [self.webViewController.webView wmf_browserView];
        self.linkPreviewingContext =
            [self registerForPreviewingWithDelegate:self sourceView:previewView];
        for (UIGestureRecognizer* r in previewView.gestureRecognizers) {
            [r requireGestureRecognizerToFail:self.linkPreviewingContext.previewingGestureRecognizerForFailureRelationship];
        }
    } unavailable:^{
        [self unregisterForPreviewing];
    }];
}

- (void)unregisterForPreviewing {
    if (self.linkPreviewingContext) {
        [self unregisterForPreviewingWithContext:self.linkPreviewingContext];
        self.linkPreviewingContext = nil;
    }
}

- (nullable UIViewController*)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                      viewControllerForLocation:(CGPoint)location {
    JSValue* peekElement = [self.webViewController htmlElementAtLocation:location];
    if (!peekElement) {
        return nil;
    }

    NSURL* peekURL = [self.webViewController urlForHTMLElement:peekElement];
    if (!peekURL) {
        return nil;
    }

    UIViewController* peekVC = [self viewControllerForPreviewURL:peekURL];
    if (peekVC) {
        [[PiwikTracker wmf_configuredInstance] wmf_logActionPreviewInContext:self contentType:nil];
        self.webViewController.isPeeking = YES;
        previewingContext.sourceRect     = [self.webViewController rectForHTMLElement:peekElement];
        return peekVC;
    }

    return nil;
}

- (UIViewController*)viewControllerForPreviewURL:(NSURL*)url {
    if ([url.absoluteString isEqualToString:@""]) {
        return nil;
    }
    if (![url wmf_isInternalLink]) {
        if ([url wmf_isCitation]) {
            return nil;
        }
        if ([url.scheme hasPrefix:@"http"]) {
            return [[SFSafariViewController alloc] initWithURL:url];
        }
    } else {
        if (![url wmf_isIntraPageFragment]) {
            return [[WMFArticleViewController alloc] initWithArticleTitle:[[MWKTitle alloc] initWithURL:url]
                                                                dataStore:self.dataStore];
        }
    }
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController*)viewControllerToCommit {
    if ([viewControllerToCommit isKindOfClass:[WMFArticleViewController class]]) {
        [self pushArticleViewController:(WMFArticleViewController*)viewControllerToCommit contentType:nil animated:YES];
    } else {
        [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

#pragma mark - Article Navigation


- (void)pushArticleViewController:(WMFArticleViewController*)articleViewController contentType:(nullable id<WMFAnalyticsContentTypeProviding>)contentType animated:(BOOL)animated {
    [[PiwikTracker wmf_configuredInstance] wmf_logActionTapThroughInContext:self contentType:contentType];
    [self wmf_pushArticleViewController:articleViewController animated:YES];
}

- (void)pushArticleViewControllerWithTitle:(MWKTitle*)title contentType:(nullable id<WMFAnalyticsContentTypeProviding>)contentType animated:(BOOL)animated {
    WMFArticleViewController* articleViewController =
        [[WMFArticleViewController alloc] initWithArticleTitle:title
                                                     dataStore:self.dataStore];
    [self pushArticleViewController:articleViewController contentType:contentType animated:animated];
}

#pragma mark - WMFArticleListTableViewControllerDelegate

- (void)listViewContoller:(WMFArticleListTableViewController*)listController didSelectTitle:(MWKTitle*)title {
    if ([self presentedViewController]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    id<WMFAnalyticsContentTypeProviding> contentType = nil;
    if ([listController conformsToProtocol:@protocol(WMFAnalyticsContentTypeProviding)]) {
        contentType = (id<WMFAnalyticsContentTypeProviding>)listController;
    }
    [self pushArticleViewControllerWithTitle:title contentType:contentType animated:YES];
}

- (UIViewController*)listViewContoller:(WMFArticleListTableViewController*)listController viewControllerForPreviewingTitle:(MWKTitle*)title {
    return [[WMFArticleViewController alloc] initWithArticleTitle:title
                                                        dataStore:self.dataStore];
}

- (void)listViewContoller:(WMFArticleListTableViewController*)listController didCommitToPreviewedViewController:(UIViewController*)viewController {
    if ([self presentedViewController]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    if ([viewController isKindOfClass:[WMFArticleViewController class]]) {
        id<WMFAnalyticsContentTypeProviding> contentType = nil;
        if ([listController conformsToProtocol:@protocol(WMFAnalyticsContentTypeProviding)]) {
            contentType = (id<WMFAnalyticsContentTypeProviding>)listController;
        }
        [self pushArticleViewController:(WMFArticleViewController*)viewController contentType:contentType animated:YES];
    } else {
        [self presentViewController:viewController animated:YES completion:nil];
    }
}

#pragma mark - WMFAnalyticsContextProviding

- (NSString*)analyticsContext {
    return @"Article";
}

- (NSString*)analyticsName {
    return [self.articleTitle.site urlDomainWithLanguage];
}

@end

NS_ASSUME_NONNULL_END
