#import "WMFArticleContainerViewController.h"
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

// Networking
#import "WMFArticleFetcher.h"

// View
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIScrollView+WMFContentOffsetUtils.h"
#import "UIWebView+WMFTrackingView.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "UIViewController+WMFOpenExternalUrl.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleContainerViewController ()
<WMFWebViewControllerDelegate,
 UINavigationControllerDelegate,
 WMFArticleHeaderImageGalleryViewControllerDelegate,
 WMFImageGalleryViewControllerDelegate,
 WMFSearchPresentationDelegate,
 WMFTableOfContentsViewControllerDelegate,
 SectionEditorViewControllerDelegate>

@property (nonatomic, strong, readwrite) MWKTitle* articleTitle;
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;

// Data
@property (nonatomic, strong, readwrite, nullable) MWKArticle* article;
@property (nonatomic, strong, readonly) MWKHistoryEntry* historyEntry;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readonly) MWKHistoryList* recentPages;

// Fetchers
@property (nonatomic, strong, null_resettable) WMFArticleFetcher* articleFetcher;
@property (nonatomic, strong, nullable) AnyPromise* articleFetcherPromise;

// Children
@property (nonatomic, strong) WebViewController* webViewController;
@property (nonatomic, strong) WMFArticleHeaderImageGalleryViewController* headerGallery;
@property (nonatomic, strong) WMFArticleListCollectionViewController* readMoreListViewController;
@property (nonatomic, strong, null_resettable) WMFTableOfContentsViewController* tableOfContentsViewController;
@property (nonatomic, strong) WMFSaveButtonController* saveButtonController;

// Logging
@property (strong, nonatomic, nullable) WMFShareFunnel* shareFunnel;
@property (strong, nonatomic, nullable) WMFShareOptionsController* shareOptionsController;

// Views
@property (nonatomic, strong) MASConstraint* headerHeightConstraint;

@end

@implementation WMFArticleContainerViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithArticleTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);

    self = [super init];
    if (self) {
        self.articleTitle = title;
        self.dataStore    = dataStore;
        [self observeArticleUpdates];
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

#pragma mark - Accessors

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.articleTitle];
}

- (void)setArticle:(nullable MWKArticle*)article {
    // HAX: Need to check the window to see if we are on screen, isViewLoaded is not enough.
    // see http://stackoverflow.com/a/2777460/48311
//    NSAssert([self isViewLoaded] && self.view.window, @"Cannot set article before viewDidLoad");

    _article                       = article;
    self.webViewController.article = _article;
    [self.headerGallery setImagesFromArticle:_article];
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

- (WMFTableOfContentsViewController*)tableOfContentsViewController {
    NSParameterAssert(self.article);
    if (!_tableOfContentsViewController) {
        _tableOfContentsViewController = [[WMFTableOfContentsViewController alloc] initWithSectionList:[self.article sectionsWithFakeReadMoreSection] delegate:self];
    }
    return _tableOfContentsViewController;
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

- (WMFSaveButtonController*)saveButtonController {
    if (!_saveButtonController) {
        _saveButtonController = [[WMFSaveButtonController alloc] init];
        UIButton* saveButton = [UIButton wmf_buttonType:WMFButtonTypeBookmark handler:nil];
        [saveButton sizeToFit];
        _saveButtonController.button        = saveButton;
        _saveButtonController.savedPageList = self.savedPages;
        _saveButtonController.title         = self.articleTitle;
    }
    return _saveButtonController;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleUpdatedWithNotification:) name:MWKArticleSavedNotification object:nil];
}

- (void)unobserveArticleUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MWKArticleSavedNotification object:nil];
}

#pragma mark - Toolbar

- (void)setupToolbar {
    if (!self.article) {
        self.toolbarItems = nil;
        return;
    }

    NSMutableArray<UIBarButtonItem*>* toolbarItems = [@[
                                                          [self refreshToolbarItem], [self flexibleSpaceToolbarItem],
                                                          [self shareToolbarItem], [self flexibleSpaceToolbarItem],
                                                          [self saveToolbarItem]
                                                      ] mutableCopy];

    if (!self.article.isMain) {
        [toolbarItems addObjectsFromArray:@[[self flexibleSpaceToolbarItem], [self tableOfContentsToolbarItem]]];
    }

    self.toolbarItems                      = toolbarItems;
    self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItemWithDelegate:self];
}

- (UIBarButtonItem*)paddingToolbarItem {
    UIBarButtonItem* item =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    item.width = 10.f;
    return item;
}

- (UIBarButtonItem*)saveToolbarItem {
    return [[UIBarButtonItem alloc] initWithCustomView:self.saveButtonController.button];;
}

- (UIBarButtonItem*)refreshToolbarItem {
    @weakify(self);
    return [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                           handler:^(id _Nonnull sender) {
        @strongify(self);
        [self fetchArticle];
    }];
}

- (UIBarButtonItem*)flexibleSpaceToolbarItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                         target:nil
                                                         action:NULL];
}

- (UIBarButtonItem*)shareToolbarItem {
    @weakify(self);
    return [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                           handler:^(id sender){
        @strongify(self);
        [self shareArticleWithTextSnippet:[self.webViewController selectedText] fromButton:sender];
    }];
}

- (UIBarButtonItem*)tableOfContentsToolbarItem {
    @weakify(self);
    UIBarButtonItem* tocToolbarItem = [[UIBarButtonItem alloc] bk_initWithImage:[UIImage imageNamed:@"toc"]
                                                                          style:UIBarButtonItemStylePlain
                                                                        handler:^(id sender){
        @strongify(self);
        [self.tableOfContentsViewController selectAndScrollToSection:[self.webViewController currentVisibleSection] animated:NO];
        [self presentViewController:self.tableOfContentsViewController animated:YES completion:NULL];
    }];
    tocToolbarItem.tintColor = [UIColor blackColor];
    return tocToolbarItem;
}

#pragma mark - ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveWithNotification:) name:UIApplicationWillResignActiveNotification object:nil];

    [self setupWebView];

    self.article = [self.dataStore existingArticleWithTitle:self.articleTitle];

    [self fetchArticle];
    [self setupToolbar];
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

#pragma mark - TableOfContentsViewControllerDelegate

- (void)tableOfContentsController:(WMFTableOfContentsViewController*)controller didSelectSection:(MWKSection*)section {
    //Don't dismiss immediately - it looks jarring - let the user see the ToC selection before dismissing
    dispatchOnMainQueueAfterDelayInSeconds(0.25, ^{
        [self dismissViewControllerAnimated:YES completion:NULL];
        [self.webViewController scrollToSection:section];
    });
}

- (void)tableOfContentsControllerDidCancel:(WMFTableOfContentsViewController*)controller {
    [self dismissViewControllerAnimated:YES completion:NULL];
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
    return self.article.site;
}

- (void)didSelectArticle:(MWKArticle*)article sender:(WMFSearchViewController*)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewControllerWithTitle:article.title discoveryMethod:MWKHistoryDiscoveryMethodSearch dataStore:self.dataStore];
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

@end

NS_ASSUME_NONNULL_END
