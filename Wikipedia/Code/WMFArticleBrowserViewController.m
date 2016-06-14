
#import "WMFArticleBrowserViewController.h"
#import "UIColor+WMFHexColor.h"
#import "Wikipedia-Swift.h"

#import "MWKDataStore.h"
#import "MWKUserDataStore.h"
#import "MWKLanguageLinkController.h"

#import "MWKTitle.h"
#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"
#import "MWKLanguageLink.h"

#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit+UIKit.h>

#import "UIViewController+WMFSearch.h"
#import "WMFSaveButtonController.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "PiwikTracker+WMFExtensions.h"
#import "WMFShareFunnel.h"
#import "UIToolbar+WMFStyling.h"

#import "WMFArticleViewController.h"
#import "WMFLanguagesViewController.h"

#import <Tweaks/FBTweakInline.h>

NS_ASSUME_NONNULL_BEGIN

BOOL useSingleBrowserController() {
    return FBTweakValue(@"Article", @"Browser", @"Use Article Browser", NO);
}

@interface WMFArticleBrowserViewController ()<UINavigationControllerDelegate, WMFArticleViewControllerDelegate, WMFLanguagesViewControllerDelegate, UIToolbarDelegate, UINavigationBarDelegate>

@property (nonatomic, strong, readwrite) UINavigationController* internalNavigationController;
@property (nonatomic, strong) NSMutableArray<MWKTitle*>* navigationTitleStack;
@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, strong) WMFArticleViewController* currentViewController;

@property (nonatomic, strong, nullable) WMFArticleViewController* initialViewController;

@property (strong, nonatomic) UIProgressView* progressView;

@property (nonatomic, strong) UINavigationBar* navigationBar;
@property (nonatomic, strong) UIToolbar* bottomBar;

@property (nonatomic, strong) UIBarButtonItem* refreshToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* backToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* forwardToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* saveToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* languagesToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* shareToolbarItem;
@property (nonatomic, strong) UIBarButtonItem* tableOfContentsToolbarItem;

@property (nonatomic, strong) WMFSaveButtonController* saveButtonController;

@end

@implementation WMFArticleBrowserViewController

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

+ (WMFArticleBrowserViewController*)browserViewControllerWithDataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(dataStore);
    WMFArticleBrowserViewController* vc = [[WMFArticleBrowserViewController alloc] initWithDataStore:dataStore];
    return vc;
}

+ (WMFArticleBrowserViewController*)browserViewControllerWithDataStore:(MWKDataStore*)dataStore articleTitle:(MWKTitle*)title restoreScrollPosition:(BOOL)restoreScrollPosition {
    if (!restoreScrollPosition) {
        title = [title wmf_titleWithoutFragment];
    }
    WMFArticleViewController* vc = [[WMFArticleViewController alloc] initWithArticleTitle:title dataStore:dataStore];
    return [self browserViewControllerWithArticleViewController:vc];
}

+ (WMFArticleBrowserViewController*)browserViewControllerWithArticleViewController:(WMFArticleViewController*)viewController {
    NSParameterAssert(viewController);
    WMFArticleBrowserViewController* vc = [[WMFArticleBrowserViewController alloc] initWithDataStore:viewController.dataStore];
    vc.initialViewController = viewController;
    return vc;
}

- (MWKTitle*)titleOfCurrentArticle {
    return [self.navigationTitleStack lastObject];
}

#pragma mark - Accessors

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

- (UIBarButtonItem*)refreshToolbarItem {
    if (!_refreshToolbarItem) {
        _refreshToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh"]
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(fetchArticleIfNeeded)];
    }
    return _refreshToolbarItem;
}

- (UIBarButtonItem*)backToolbarItem {
    if (!_backToolbarItem) {
        _backToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"chevron-left"]
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(navigateBack)];
    }
    return _backToolbarItem;
}

- (UIBarButtonItem*)forwardToolbarItem {
    if (!_forwardToolbarItem) {
        _forwardToolbarItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"chevron-right"]
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(navigateForward)];
    }
    return _forwardToolbarItem;
}

- (UIBarButtonItem*)flexibleSpaceToolbarItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                         target:nil
                                                         action:NULL];
}

- (UIBarButtonItem*)shareToolbarItem {
    if (!_shareToolbarItem) {
        _shareToolbarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showShareSheet)];
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

- (UINavigationController*)internalNavigationController {
    if (!_internalNavigationController) {
        UINavigationController* nav = [[UINavigationController alloc] init];
        nav.view.clipsToBounds  = NO;
        nav.navigationBarHidden = YES;
        nav.toolbarHidden       = YES;
        [self addChildViewController:nav];
        [self.view insertSubview:nav.view atIndex:0];
        [nav.view mas_makeConstraints:^(MASConstraintMaker* make) {
            make.leading.and.trailing.equalTo(self.view);
            make.top.equalTo(self.navigationBar.mas_bottom);
            make.bottom.equalTo(self.bottomBar.mas_top);
        }];
        nav.delegate = self;
        [nav didMoveToParentViewController:self];
        _internalNavigationController = nav;
    }
    return _internalNavigationController;
}

#pragma mark - UIViewController

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    if (bar == self.navigationBar) {
        return UIBarPositionTopAttached;
    }
    return UIBarPositionBottom;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;

    UIImage* w = [UIImage imageNamed:@"W"];
    self.navigationItem.titleView           = [[UIImageView alloc] initWithImage:w];
    self.navigationItem.titleView.tintColor = [UIColor wmf_readerWGray];

    @weakify(self);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] bk_initWithImage:[UIImage imageNamed:@"close"] style:UIBarButtonItemStylePlain handler:^(id sender) {
        @strongify(self);
        [self dismissViewControllerAnimated:YES completion:NULL];
    }];
    self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItem];

    UINavigationBar* bar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
    bar.barTintColor = [UIColor blackColor];
    bar.tintColor    = [UIColor whiteColor];
    bar.translucent  = YES;
    bar.delegate     = self;
    [bar pushNavigationItem:self.navigationItem animated:NO];
    [self.view addSubview:bar];
    [bar mas_makeConstraints:^(MASConstraintMaker* make) {
        make.top.equalTo(self.mas_topLayoutGuide);
        make.leading.and.trailing.equalTo(self.view);
    }];
    self.navigationBar = bar;

    UIToolbar* bottom = [[UIToolbar alloc] initWithFrame:CGRectZero];
    [bottom wmf_applySolidWhiteBackgroundWithTopShadow];

    bottom.delegate = self;
    [self.view addSubview:bottom];
    [bottom mas_makeConstraints:^(MASConstraintMaker* make) {
        make.bottom.equalTo(self.view.mas_bottom);
        make.leading.and.trailing.equalTo(self.view);
    }];
    self.bottomBar = bottom;

    self.navigationTitleStack = [NSMutableArray array];

    if (self.initialViewController) {
        [self pushArticleViewController:self.initialViewController animated:NO];
        [self updateToolbar];
        self.initialViewController = nil;
    }
    [self addProgressView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.view bringSubviewToFront:self.progressView];
}

#pragma mark - Navigation

- (void)pushArticleWithTitle:(MWKTitle*)title restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated {
    WMFArticleViewController* articleViewController =
        [[WMFArticleViewController alloc] initWithArticleTitle:title
                                                     dataStore:self.dataStore];
    [self pushArticleViewController:articleViewController animated:animated];
}

- (void)pushArticleWithTitle:(MWKTitle*)title animated:(BOOL)animated {
    [self pushArticleWithTitle:title restoreScrollPosition:NO animated:animated];
}

- (void)pushArticleViewController:(WMFArticleViewController*)viewController animated:(BOOL)animated {
    viewController.delegate = self;
    [[PiwikTracker wmf_configuredInstance] wmf_logView:viewController];
    [self.internalNavigationController pushViewController:viewController animated:animated];
}

- (void)navigateBack {
    NSUInteger previousIndex = [self previousIndex];
    NSParameterAssert(previousIndex != NSNotFound);
    if (previousIndex == NSNotFound) {
        return;
    }
    self.currentViewController = [self.internalNavigationController viewControllers][previousIndex];
    self.currentIndex          = previousIndex;
    [self.internalNavigationController popViewControllerAnimated:YES];
}

- (void)navigateForward {
    NSUInteger nextIndex = [self nextIndex];
    NSParameterAssert(nextIndex != NSNotFound);
    if (nextIndex == NSNotFound) {
        return;
    }
    WMFArticleViewController* articleViewController =
        [[WMFArticleViewController alloc] initWithArticleTitle:self.navigationTitleStack[nextIndex]
                                                     dataStore:self.dataStore];
    self.currentViewController = articleViewController;
    self.currentIndex          = nextIndex;
    [self pushArticleViewController:articleViewController animated:YES];
}

- (NSUInteger)previousIndex {
    if (self.currentIndex == 0 || self.currentIndex == NSNotFound) {
        return NSNotFound;
    }
    return self.currentIndex - 1;
}

- (NSUInteger)nextIndex {
    if (self.currentIndex + 1 > [self.navigationTitleStack count] - 1) {
        return NSNotFound;
    }
    return self.currentIndex + 1;
}

#pragma mark - Progress

- (void)addProgressView {
    NSAssert(!self.progressView.superview, @"Illegal attempt to re-add progress view.");
    [self.view addSubview:self.progressView];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker* make) {
        make.top.equalTo(self.navigationBar.mas_bottom);
        make.left.equalTo(self.progressView.superview.mas_left);
        make.right.equalTo(self.progressView.superview.mas_right);
        make.height.equalTo(@2.0);
    }];
    [self hideProgressViewAnimated:NO];
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

- (void)updateProgress:(CGFloat)progress animated:(BOOL)animated {
    if (progress < self.progressView.progress) {
        return;
    }
    if (self.progressView.alpha < 0.1) {
        [self showProgressViewAnimated:YES];
    }

    [self.progressView setProgress:progress animated:animated];
}

- (void)completeAndHideProgress {
    [self updateProgress:1.0 animated:YES];
    dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
        [self hideProgressViewAnimated:YES];
    });
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

#pragma mark - Toolbar Setup

- (void)updateToolbar {
    [self updateToolbarItemsIfNeeded];
    [self updateToolbarItemEnabledState];
}

- (void)updateToolbarItemsIfNeeded {
    if (!self.saveButtonController) {
        self.saveButtonController = [[WMFSaveButtonController alloc] initWithBarButtonItem:self.saveToolbarItem savedPageList:self.dataStore.userDataStore.savedPageList title:[[self currentViewController] articleTitle]];
    } else {
        self.saveButtonController.title = [[self currentViewController] articleTitle];
    }

    self.saveButtonController.analyticsContext = [self currentViewController];

    NSArray<UIBarButtonItem*>* toolbarItems =
        [NSArray arrayWithObjects:
         self.backToolbarItem, [UIBarButtonItem wmf_barButtonItemOfFixedWidth:36.0],
         self.forwardToolbarItem, [self flexibleSpaceToolbarItem],
         self.shareToolbarItem, [UIBarButtonItem wmf_barButtonItemOfFixedWidth:24.f],
         self.saveToolbarItem, [UIBarButtonItem wmf_barButtonItemOfFixedWidth:18.f],
         self.languagesToolbarItem, [UIBarButtonItem wmf_barButtonItemOfFixedWidth:24.0],
         self.tableOfContentsToolbarItem,
         nil];

    if (self.bottomBar.items.count != toolbarItems.count) {
        // HAX: only update toolbar if # of items has changed, otherwise items will (somehow) get lost
        [self.bottomBar setItems:toolbarItems];
    }
}

- (void)updateToolbarItemEnabledState {
    self.backToolbarItem.enabled            = [self previousIndex] != NSNotFound;
    self.forwardToolbarItem.enabled         = [self nextIndex] != NSNotFound;
    self.refreshToolbarItem.enabled         = [[self currentViewController] canRefresh];
    self.shareToolbarItem.enabled           = [[self currentViewController] canShare];
    self.languagesToolbarItem.enabled       = [[self currentViewController] hasLanguages];
    self.tableOfContentsToolbarItem.enabled = [[self currentViewController] hasTableOfContents];
}

#pragma mark - Reload

- (void)fetchArticleIfNeeded {
    [[self currentViewController] fetchArticleIfNeeded];
}

#pragma mark - ToC

- (void)showTableOfContents {
    [[self currentViewController] showTableOfContents];
}

#pragma mark - Share

- (void)showShareSheet {
    [[self currentViewController] shareArticleFromButton:self.shareToolbarItem];
}

#pragma mark - Languages

- (void)showLanguagePicker {
    WMFArticleLanguagesViewController* languagesVC = [WMFArticleLanguagesViewController articleLanguagesViewControllerWithTitle:[[self currentViewController] articleTitle]];
    languagesVC.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:nil];
}

- (void)languagesController:(WMFArticleLanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language {
    [self dismissViewControllerAnimated:YES completion:^{
        WMFArticleViewController* vc = [[WMFArticleViewController alloc] initWithArticleTitle:language.title dataStore:self.dataStore];
        [self.internalNavigationController pushViewController:vc animated:YES];
    }];
}

#pragma mark - WMFArticleViewControllerDelegate

- (void)articleController:(WMFArticleViewController*)controller didUpdateArticleLoadProgress:(CGFloat)progress animated:(BOOL)animated {
    [self updateProgress:progress animated:animated];
}

- (void)articleControllerDidLoadArticle:(WMFArticleViewController*)controller {
    [self updateToolbar];
    [self completeAndHideProgress];
}

- (void)articleControllerDidFailToLoadArticle:(WMFArticleViewController*)controller {
    [self hideProgressViewAnimated:YES];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController*)navigationController willShowViewController:(UIViewController*)viewController animated:(BOOL)animated {
    WMFArticleViewController* vc = (WMFArticleViewController*)[self.internalNavigationController topViewController];
    vc.delegate = nil;

    if (self.currentViewController != viewController) {
        //unknown view controller being displayed
        //rebuild the navigation stack
        self.navigationTitleStack = [[[self.internalNavigationController viewControllers] bk_map:^id (WMFArticleViewController* obj) {
            return obj.articleTitle;
        }] mutableCopy];
        self.currentViewController = (WMFArticleViewController*)viewController;
        self.currentIndex          = [[navigationController viewControllers] count] - 1;
    }

    vc          = (WMFArticleViewController*)viewController;
    vc.delegate = self;
    //HACK: the transition view wrapping the view controller clips subcviews
    //We need to so this to make sure the webview shows through the navigation bar when scrolling behind it
    vc.view.superview.superview.clipsToBounds = NO;

    [self updateToolbar];
}

- (void)navigationController:(UINavigationController*)navigationController didShowViewController:(UIViewController*)viewController animated:(BOOL)animated {
    WMFArticleViewController* vc = (WMFArticleViewController*)viewController;
    //Delay this so any visual updates to lists are postponed until the article after the article is displayed
    //Some lists (like history) will show these artifacts as the push navigation is occuring.
    dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
        MWKHistoryList* historyList = vc.dataStore.userDataStore.historyList;
        [historyList addPageToHistoryWithTitle:vc.articleTitle];
        [historyList save];
    });
}

- (nullable MWKArticle*)currentArticle {
    return [[self currentViewController] article];
}

@end

@implementation UIViewController (WMFArticlePresentation)

- (void)wmf_pushArticleWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore restoreScrollPosition:(BOOL)restoreScrollPosition animated:(BOOL)animated {
    if (!restoreScrollPosition) {
        title = [title wmf_titleWithoutFragment];
    }
    WMFArticleViewController* vc = [[WMFArticleViewController alloc] initWithArticleTitle:title dataStore:dataStore];
    [self wmf_pushArticleViewController:vc animated:animated];
}

- (void)wmf_pushArticleWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore animated:(BOOL)animated {
    [self wmf_pushArticleWithTitle:title dataStore:dataStore restoreScrollPosition:NO animated:animated];
}

/**
 *  HACK:// need to support multiple navigation schemes, so its easiest to just interrogate the stack for known situations.
 *  When removing one of the navigation options, this can be cleaned up
 */
- (void)wmf_pushArticleViewController:(WMFArticleViewController*)viewController animated:(BOOL)animated {
    if (useSingleBrowserController()) {
        if ([self isKindOfClass:[WMFArticleViewController class]] && [[self.navigationController parentViewController] isKindOfClass:[WMFArticleBrowserViewController class]]) {
            [(WMFArticleBrowserViewController*)[self.navigationController parentViewController] pushArticleViewController:viewController animated:animated];
        } else if ([self isKindOfClass:[WMFArticleBrowserViewController class]]) {
            [(WMFArticleBrowserViewController*)self pushArticleViewController:viewController animated:animated];
        } else if ([[self presentedViewController] isKindOfClass:[WMFArticleBrowserViewController class]]) {
            [(WMFArticleBrowserViewController*)[self presentedViewController] pushArticleViewController:viewController animated:animated];
        } else {
            [self presentViewController:[WMFArticleBrowserViewController browserViewControllerWithArticleViewController:viewController] animated:animated completion:NULL];
        }
    } else {
        if (self.navigationController != nil) {
            [self.navigationController pushViewController:viewController animated:animated];
        } else if ([[self.childViewControllers firstObject] isKindOfClass:[UITabBarController class]]) {
            UITabBarController* tab     = (UITabBarController*)[self.childViewControllers firstObject];
            UINavigationController* nav = [tab selectedViewController];
            [nav pushViewController:viewController animated:animated];
        } else {
            NSAssert(0, @"Unexpected view controller hierarchy");
        }
        [[PiwikTracker wmf_configuredInstance] wmf_logView:viewController];

        dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
            MWKHistoryList* historyList = viewController.dataStore.userDataStore.historyList;
            [historyList addPageToHistoryWithTitle:viewController.articleTitle];
            [historyList save];
        });
    }
}

@end




NS_ASSUME_NONNULL_END