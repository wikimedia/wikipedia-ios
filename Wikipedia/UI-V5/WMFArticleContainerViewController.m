#import "WMFArticleContainerViewController_Private.h"
#import "Wikipedia-Swift.h"

// Frameworks
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit+UIKit.h>

// Controller
#import "WebViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "WMFSaveButtonController.h"
#import "WMFArticleContainerViewController_Transitioning.h"
#import "WMFArticleHeaderImageGalleryViewController.h"
#import "WMFRelatedTitleListDataSource.h"
#import "WMFArticleListCollectionViewController.h"
#import "UITabBarController+WMFExtensions.h"
#import "WMFShareOptionsController.h"
#import "WMFImageGalleryViewController.h"
#import "UIViewController+WMFSearchButton.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "SectionEditorViewController.h"
#import "LanguagesViewController.h"

//Funnel
#import "WMFShareFunnel.h"
#import "ProtectedEditAttemptFunnel.h"


// Model
#import "MWKDataStore.h"
#import "MWKArticle+WMFAnalyticsLogging.h"
#import "MWKCitation.h"
#import "MWKTitle.h"
#import "MWKSavedPageList.h"
#import "MWKUserDataStore.h"
#import "MWKArticle+WMFSharing.h"
#import "MWKArticlePreview.h"
#import "MWKHistoryList.h"
#import "MWKProtectionStatus.h"
#import "MWKSectionList.h"
#import "MWKLanguageLink.h"

// Networking
#import "WMFArticleFetcher.h"

// View
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "UIWebView+WMFTrackingView.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "UIViewController+WMFOpenExternalUrl.h"

#import "NSString+WMFPageUtilities.h"
#import "NSURL+WMFLinkParsing.h"
#import "NSURL+Extras.h"

@import SafariServices;

@import JavaScriptCore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleContainerViewController ()
<WMFWebViewControllerDelegate,
 UINavigationControllerDelegate,
 WMFArticleHeaderImageGalleryViewControllerDelegate,
 WMFImageGalleryViewControllerDelegate,
 WMFSearchPresentationDelegate,
 SectionEditorViewControllerDelegate,
 UIViewControllerPreviewingDelegate,
 LanguageSelectionDelegate>

@property (nonatomic, strong, readwrite) MWKTitle* articleTitle;
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;
@property (nonatomic, assign, readwrite) MWKHistoryDiscoveryMethod discoveryMethod;

// Data
@property (nonatomic, strong, readonly) MWKHistoryEntry* historyEntry;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readonly) MWKHistoryList* recentPages;

// Fetchers
@property (nonatomic, strong, null_resettable) WMFArticleFetcher* articleFetcher;
@property (nonatomic, strong, nullable) AnyPromise* articleFetcherPromise;

// Children
@property (nonatomic, strong) WMFArticleHeaderImageGalleryViewController* headerGallery;
@property (nonatomic, strong) WMFArticleListCollectionViewController* readMoreListViewController;
@property (nonatomic, strong) WMFSaveButtonController* saveButtonController;

// Logging
@property (strong, nonatomic, nullable) WMFShareFunnel* shareFunnel;
@property (strong, nonatomic, nullable) WMFShareOptionsController* shareOptionsController;

// Views
@property (nonatomic, strong) MASConstraint* headerHeightConstraint;
@property (nonatomic, strong) UIBarButtonItem* refreshToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* saveToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* languagesToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* shareToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* tableOfContentsToolbarItem;

// Previewing
@property (nonatomic, weak) id<UIViewControllerPreviewing> linkPreviewingContext;

@end

@implementation WMFArticleContainerViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore
                     discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);

    self = [super init];
    if (self) {
        self.articleTitle    = title;
        self.dataStore       = dataStore;
        self.discoveryMethod = discoveryMethod;
        [self observeArticleUpdates];
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

#pragma mark - Article languages

- (void)showLanguagePicker {
    LanguagesViewController* languagesVC = [LanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    languagesVC.downloadLanguagesForCurrentArticle = YES;
    languagesVC.languageSelectionDelegate          = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:nil];
}

- (void)languageSelected:(MWKLanguageLink*)langLink sender:(LanguagesViewController*)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewControllerWithTitle:langLink.title discoveryMethod:MWKHistoryDiscoveryMethodLink dataStore:self.dataStore];
    }];
}

#pragma mark - Accessors

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.articleTitle];
}

- (void)setArticle:(nullable MWKArticle*)article {
    if (_article == article) {
        return;
    }

    _tableOfContentsViewController = nil;
    _shareFunnel                   = nil;
    _shareOptionsController        = nil;
    [self.articleFetcher cancelFetchForPageTitle:_articleTitle];

    _article                       = article;
    self.webViewController.article = _article;
    [self.headerGallery setImagesFromArticle:_article];

    [self setupToolbar];
    [self createTableOfContentsViewController];
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

- (WMFArticleListCollectionViewController*)readMoreListViewController {
    if (!_readMoreListViewController) {
        _readMoreListViewController             = [[WMFSelfSizingArticleListCollectionViewController alloc] init];
        _readMoreListViewController.recentPages = self.recentPages;
        _readMoreListViewController.dataStore   = self.dataStore;
        _readMoreListViewController.savedPages  = self.savedPages;
        WMFRelatedTitleListDataSource* relatedTitlesDataSource =
            [[WMFRelatedTitleListDataSource alloc] initWithTitle:self.articleTitle
                                                       dataStore:self.dataStore
                                                   savedPageList:self.savedPages
                                                     resultLimit:3];
        // TODO: fetch lazily
        [relatedTitlesDataSource fetch];
        // TEMP: configure extract chars
        _readMoreListViewController.dataSource = relatedTitlesDataSource;
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
        // TODO: add "last edited by" & "wikipedia logo"
        // !!!: be sure to add footers in the order specified by WMFArticleFooterViewIndex
        [_webViewController setFooterViewControllers:@[self.readMoreListViewController]];
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

#pragma mark - Toolbar Setup

- (void)setupToolbar {
    [self updateToolbarItemsIfNeeded];
    [self updateToolbarItemEnabledState];
}

- (void)updateToolbarItemsIfNeeded {
    if (!self.saveButtonController) {
        self.saveButtonController = [[WMFSaveButtonController alloc] initWithBarButtonItem:self.saveToolbarItem savedPageList:self.savedPages title:self.articleTitle];
    }

    NSMutableArray<UIBarButtonItem*>* toolbarItems =
        [NSMutableArray arrayWithObjects:
         self.refreshToolbarItem, [self flexibleSpaceToolbarItem],
         self.shareToolbarItem, [UIBarButtonItem wmf_barButtonItemOfFixedWidth:24.f],
         self.saveToolbarItem, [UIBarButtonItem wmf_barButtonItemOfFixedWidth:18.f],
         self.languagesToolbarItem,
         nil];

    if (!self.article.isMain) {
        [toolbarItems addObjectsFromArray:@[[self flexibleSpaceToolbarItem], self.tableOfContentsToolbarItem]];
    }

    if (self.toolbarItems.count != toolbarItems.count) {
        // HAX: only update toolbar if # of items has changed, otherwise items will (somehow) get lost
        [self setToolbarItems:toolbarItems animated:YES];
    }
}

- (void)updateToolbarItemEnabledState {
    self.refreshToolbarItem.enabled         = self.article != nil;
    self.tableOfContentsToolbarItem.enabled = self.article != nil;
    self.shareToolbarItem.enabled           = self.article != nil;
    self.languagesToolbarItem.enabled       = self.article.languagecount > 1;
}

#pragma mark - Toolbar Items

- (UIBarButtonItem*)tableOfContentsToolbarItem {
    if (!_tableOfContentsToolbarItem) {
        _tableOfContentsToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toc"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(didTapTableOfContentsButton:)];
        _tableOfContentsToolbarItem.tintColor = [UIColor wmf_logoBlue];
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

- (UIBarButtonItem*)refreshToolbarItem {
    if (!_refreshToolbarItem) {
        @weakify(self);
        _refreshToolbarItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                              handler:^(id _Nonnull sender) {
            @strongify(self);
            [self fetchArticle];
        }];
        _refreshToolbarItem.tintColor = [UIColor wmf_logoBlue];
    }
    return _refreshToolbarItem;
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
            [self shareArticleWithTextSnippet:[self.webViewController selectedText] fromButton:sender];
        }];
        _shareToolbarItem.tintColor = [UIColor wmf_logoBlue];
    }
    return _shareToolbarItem;
}

- (UIBarButtonItem*)languagesToolbarItem {
    if (!_languagesToolbarItem) {
        _languagesToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"language"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(showLanguagePicker)];
        _languagesToolbarItem.tintColor = [UIColor wmf_logoBlue];
    }
    return _languagesToolbarItem;
}

#pragma mark - ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupToolbar];
    self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItemWithDelegate:self];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveWithNotification:) name:UIApplicationWillResignActiveNotification object:nil];

    [self setupWebView];

    self.article = [self.dataStore existingArticleWithTitle:self.articleTitle];
    [self fetchArticle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForPreviewingIfAvailable];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection*)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self registerForPreviewingIfAvailable];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSUserDefaults standardUserDefaults] wmf_setOpenArticleTitle:self.articleTitle];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self saveWebViewScrollOffset];
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults] wmf_setOpenArticleTitle:nil];
}

#pragma mark - Web View Setup

- (void)setupWebView {
    [self addChildViewController:self.webViewController];
    [self.view addSubview:self.webViewController.view];
    [self.webViewController.view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.leading.trailing.top.and.bottom.equalTo(self.view);
    }];
    [self.webViewController didMoveToParentViewController:self];
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

- (void)fetchArticle {
    @weakify(self);
    [self unobserveArticleUpdates];
    self.articleFetcherPromise = [self.articleFetcher fetchArticleForPageTitle:self.articleTitle progress:NULL]
                                 .then(^(MWKArticle* article) {
        @strongify(self);
        [self saveWebViewScrollOffset];
        self.article = article;
    }).catch(^(NSError* error){
        @strongify(self);
        if (!self.presentingViewController) {
            // only do error handling if not presenting gallery
            DDLogError(@"Article Fetch Error: %@", [error localizedDescription]);
        }
    }).finally(^{
        @strongify(self);
        self.articleFetcherPromise = nil;
        [self observeArticleUpdates];
    });
}

#pragma mark - Scroll Position and Fragments

- (void)scrollWebViewToRequestedPosition {
    if (self.articleTitle.fragment) {
        [self.webViewController scrollToFragment:self.articleTitle.fragment];
    } else if ([self.historyEntry discoveryMethodRequiresScrollPositionRestore] && self.historyEntry.scrollPosition > 0) {
        [self.webViewController scrollToVerticalOffset:self.historyEntry.scrollPosition];
    }
    [self markFragmentAsProcessed];
}

- (void)markFragmentAsProcessed {
    //Create a title without the fragment so it wont be followed anymore
    self.articleTitle = [[MWKTitle alloc] initWithSite:self.articleTitle.site normalizedTitle:self.articleTitle.text fragment:nil];
}

#pragma mark - Share

- (void)shareArticleWithTextSnippet:(nullable NSString*)text fromButton:(nullable UIButton*)button {
    if (text.length == 0) {
        text = [self.article shareSnippet];
    }
    [self.shareFunnel logShareButtonTappedResultingInSelection:text];
    [self.shareOptionsController presentShareOptionsWithSnippet:text inViewController:self fromView:button];
}

#pragma mark - WebView Transition

- (void)showWebViewAtFragment:(NSString*)fragment animated:(BOOL)animated {
    [self.webViewController scrollToFragment:fragment];
}

#pragma mark - WMFWebViewControllerDelegate

- (void)webViewController:(WebViewController*)controller didLoadArticle:(MWKArticle*)article {
    [self scrollWebViewToRequestedPosition];
}

- (void)webViewController:(WebViewController*)controller didTapEditForSection:(MWKSection*)section {
    [self showEditorForSection:section];
}

- (void)webViewController:(WebViewController*)controller didTapOnLinkForTitle:(MWKTitle*)title {
    [self wmf_pushArticleViewControllerWithTitle:title discoveryMethod:MWKHistoryDiscoveryMethodLink dataStore:self.dataStore];
}

- (void)webViewController:(WebViewController*)controller didSelectText:(NSString*)text {
    [self.shareFunnel logHighlight];
}

- (void)webViewController:(WebViewController*)controller didTapShareWithSelectedText:(NSString*)text {
    [self shareArticleWithTextSnippet:text fromButton:nil];
}

#pragma mark - Analytics

- (NSString*)analyticsName {
    return [self.article analyticsName];
}

#pragma mark - WMFArticleHeadermageGalleryViewControllerDelegate

- (void)headerImageGallery:(WMFArticleHeaderImageGalleryViewController* __nonnull)gallery
     didSelectImageAtIndex:(NSUInteger)index {
    NSParameterAssert(![self.presentingViewController isKindOfClass:[WMFImageGalleryViewController class]]);
    WMFImageGalleryViewController* fullscreenGallery = [[WMFImageGalleryViewController alloc] initWithArticle:nil];
    fullscreenGallery.delegate = self;
    if (self.article) {
        fullscreenGallery.article     = self.article;
        fullscreenGallery.currentPage = index;
    } else {
        if (!self.articleFetcherPromise) {
            [self fetchArticle];
        }
        [fullscreenGallery setArticleWithPromise:self.articleFetcherPromise];
    }
    [self presentViewController:fullscreenGallery animated:YES completion:nil];
}

#pragma mark - WMFImageGalleryViewControllerDelegate

- (void)willDismissGalleryController:(WMFImageGalleryViewController* __nonnull)gallery {
    self.headerGallery.currentPage = gallery.currentPage;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WMFSearchPresentationDelegate

- (MWKDataStore*)searchDataStore {
    return self.dataStore;
}

- (MWKSite*)searchSite {
    return self.articleTitle.site;
}

- (void)didSelectTitle:(MWKTitle*)title sender:(id)sender discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewControllerWithTitle:title
                                     discoveryMethod:discoveryMethod
                                           dataStore:self.dataStore];
    }];
}

- (void)didCommitToPreviewedArticleViewController:(WMFArticleContainerViewController*)articleViewController
                                           sender:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewController:articleViewController];
    }];
}

#pragma mark - Edit Section

- (void)showEditorForSection:(MWKSection*)section {
    if (self.article.editable) {
        SectionEditorViewController* sectionEditVC = [SectionEditorViewController wmf_initialViewControllerFromClassStoryboard];
        sectionEditVC.section  = section;
        sectionEditVC.delegate = self;
        [self.navigationController pushViewController:sectionEditVC animated:YES];
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
    [self.navigationController popToViewController:self animated:YES];
    [self fetchArticle];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (void)registerForPreviewingIfAvailable {
    [self wmf_ifForceTouchAvailable:^{
        [self unregisterForPreviewing];
        self.linkPreviewingContext =
            [self registerForPreviewingWithDelegate:self sourceView:[self.webViewController.webView wmf_browserView]];
        for (UIGestureRecognizer* r in [self.webViewController.webView wmf_browserView].gestureRecognizers) {
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
        self.webViewController.isPeeking = YES;
        previewingContext.sourceRect     = [self.webViewController rectForHTMLElement:peekElement];
        return peekVC;
    }

    return nil;
}

- (UIViewController*)viewControllerForPreviewURL:(NSURL*)url {
    if (![url wmf_isInternalLink]) {
        return [[SFSafariViewController alloc] initWithURL:url];
    } else {
        if (![url wmf_isIntraPageFragment]) {
            return [[WMFArticleContainerViewController alloc] initWithArticleTitle:[[MWKTitle alloc] initWithURL:url]
                                                                         dataStore:self.dataStore
                                                                   discoveryMethod:self.discoveryMethod];
        }
    }
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController*)viewControllerToCommit {
    if ([viewControllerToCommit isKindOfClass:[WMFArticleContainerViewController class]]) {
        [self wmf_pushArticleViewController:(WMFArticleContainerViewController*)viewControllerToCommit];
    } else {
        [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

@end

NS_ASSUME_NONNULL_END
