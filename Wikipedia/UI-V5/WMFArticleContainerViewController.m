#import "WMFArticleContainerViewController.h"
#import "WMFArticleContainerViewController_Transitioning.h"
#import <BlocksKit/BlocksKit+UIKit.h>

// Frameworks
#import <Masonry/Masonry.h>

// Controller
#import "WMFArticleViewController.h"
#import "WebViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"

// Model
#import "MWKDataStore.h"
#import "MWKArticle.h"
#import "MWKCitation.h"
#import "MWKTitle.h"
#import "MWKSavedPageList.h"

#import "WMFPreviewController.h"

// Other
#import "SessionSingleton.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleContainerViewController ()
<WMFWebViewControllerDelegate, WMFArticleViewControllerDelegate, UINavigationControllerDelegate, WMFPreviewControllerDelegate>
@property (nonatomic, strong) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) MWKDataStore* dataStore;

@property (nonatomic, strong) UINavigationController* contentNavigationController;
@property (nonatomic, strong, readwrite) WMFArticleViewController* articleViewController;
@property (nonatomic, strong, readwrite) WebViewController* webViewController;

@property (nonatomic, weak, readonly) UIViewController<WMFArticleContentController>* currentArticleController;

@property (nonatomic, strong, nullable) WMFPreviewController* previewController;

@property (strong, nonatomic) UIBarButtonItem* saveButton;

@end

@implementation WMFArticleContainerViewController
@synthesize article = _article;

#pragma mark - Setup

+ (instancetype)articleContainerViewControllerWithDataStore:(MWKDataStore*)dataStore
                                                 savedPages:(MWKSavedPageList*)savedPages {
    return [[self alloc] initWithDataStore:dataStore savedPages:savedPages];
}

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore savedPages:(MWKSavedPageList*)savedPages {
    self = [super init];
    if (self) {
        self.savedPageList = savedPages;
        self.dataStore     = dataStore;
    }
    return self;
}

#pragma mark - Accessors

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.article.title];
}

- (UIViewController<WMFArticleContentController>*)currentArticleController {
    return (id)[self.contentNavigationController topViewController];
}

- (void)setArticle:(MWKArticle* __nullable)article {
    if (WMF_EQUAL(_article, isEqualToArticle:, article)) {
        return;
    }

    _article = article;

    if (self.isViewLoaded) {
        self.articleViewController.article = article;
        self.webViewController.article     = article;
    }
}

- (WMFArticleViewController*)articleViewController {
    if (!_articleViewController) {
        _articleViewController          = [WMFArticleViewController articleViewControllerWithDataStore:self.dataStore];
        _articleViewController.delegate = self;
    }
    return _articleViewController;
}

- (WebViewController*)webViewController {
    if (!_webViewController) {
        _webViewController          = [WebViewController wmf_initialViewControllerFromClassStoryboard];
        _webViewController.delegate = self;
    }
    return _webViewController;
}

#pragma mark - ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    @weakify(self)
    self.saveButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeBookmark handler:^(id sender){
        @strongify(self)
        [self toggleSave : self];
    }];
    self.navigationItem.rightBarButtonItem = self.saveButton;

    [self observeSavedPages];

    // Manually adjusting scrollview offsets to compensate for embedded navigation controller
    self.automaticallyAdjustsScrollViewInsets = NO;

    [self updateInsetsForArticleViewController];

    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:self.articleViewController];
    nav.navigationBarHidden = YES;
    nav.delegate            = self;
    [self addChildViewController:nav];
    [self.view addSubview:nav.view];
    [nav.view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.leading.trailing.top.and.bottom.equalTo(self.view);
    }];
    [nav didMoveToParentViewController:self];
    self.contentNavigationController = nav;

    if (self.article) {
        self.articleViewController.article = self.article;
        self.webViewController.article     = self.article;
    }

    [self updateSavedButtonState];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateInsetsForArticleViewController];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self updateInsetsForArticleViewController];
}

- (void)updateInsetsForArticleViewController {
    CGFloat topInset = [self.navigationController.navigationBar frame].size.height
                       + [[UIApplication sharedApplication] statusBarFrame].size.height;

    UIEdgeInsets adjustedInsets = UIEdgeInsetsMake(topInset,
                                                   0.0,
                                                   self.tabBarController.tabBar.frame.size.height,
                                                   0.0);

    self.articleViewController.tableView.contentInset          = adjustedInsets;
    self.articleViewController.tableView.scrollIndicatorInsets = adjustedInsets;

    //adjust offset if we are at the top
    if (self.articleViewController.tableView.contentOffset.y <= 0) {
        self.articleViewController.tableView.contentOffset = CGPointMake(0, -topInset);
    }
}

#pragma mark - WebView Transition

- (void)showWebViewAnimated:(BOOL)animated {
    [self.contentNavigationController pushViewController:self.webViewController animated:YES];
}

- (void)showWebViewAtFragment:(NSString*)fragment animated:(BOOL)animated {
    [self.webViewController scrollToFragment:fragment];
    [self showWebViewAnimated:animated];
}

#pragma mark - WMFArticleViewControllerDelegate

- (void)articleNavigator:(id<WMFArticleNavigation> __nullable)sender
      didTapCitationLink:(NSString* __nonnull)citationFragment {
    if (self.article.isCached) {
        [self showCitationWithFragment:citationFragment];
    } else {
        // TODO: fetch all sections before attempting to parse citations natively
//        if (!self.articleFetcherPromise) {
//            [self fetchArticle];
//        }
//        @weakify(self);
//        self.articleFetcherPromise.then(^(MWKArticle* _) {
//            @strongify(self);
//            [self showCitationWithFragment:citationFragment];
//        });
    }
}

- (void)articleViewController:(WMFArticleViewController* __nonnull)articleViewController
    didTapSectionWithFragment:(NSString* __nonnull)fragment {
    [self showWebViewAtFragment:fragment animated:YES];
}

- (void)showCitationWithFragment:(NSString*)fragment {
    // TODO: parse citations natively, then show citation popup control
//    NSParameterAssert(self.article.isCached);
//    MWKCitation* tappedCitation = [self.article.citations bk_match:^BOOL (MWKCitation* citation) {
//        return [citation.citationIdentifier isEqualToString:fragment];
//    }];
//    DDLogInfo(@"Tapped citation %@", tappedCitation);
//    if (!tappedCitation) {
//        DDLogWarn(@"Failed to parse citation for article %@", self.article);
//    }

    // TEMP: show webview until we figure out what to do w/ ReferencesVC
    [self showWebViewAtFragment:fragment animated:YES];
}

- (void)articleNavigator:(id<WMFArticleNavigation> __nullable)sender
        didTapLinkToPage:(MWKTitle* __nonnull)title {
    [self presentPopupForTitle:title];
}

- (void)articleNavigator:(id<WMFArticleNavigation> __nullable)sender
      didTapExternalLink:(NSURL* __nonnull)externalURL {
    [[[SessionSingleton sharedInstance] zeroConfigState] showWarningIfNeededBeforeOpeningURL:externalURL];
}

#pragma mark - WMFArticleListItemController

- (WMFArticleControllerMode)mode {
    // TEMP: WebVC (and currentArticleController) will eventually conform to this
    return self.articleViewController.mode;
}

- (void)setMode:(WMFArticleControllerMode)mode animated:(BOOL)animated {
    // TEMP: WebVC (and currentArticleController) will eventually conform to this
    [self.articleViewController setMode:mode animated:animated];
}

#pragma mark - WMFWebViewControllerDelegate

- (void)webViewController:(WebViewController*)controller didTapOnLinkForTitle:(MWKTitle*)title {
    [self presentPopupForTitle:title];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController*)navigationController willShowViewController:(UIViewController*)viewController animated:(BOOL)animated {
    if (viewController == self.articleViewController) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.contentNavigationController setNavigationBarHidden:YES animated:NO];
    } else {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        [self.contentNavigationController setNavigationBarHidden:NO animated:NO];
    }
}

#pragma mark - Popup

- (void)presentPopupForTitle:(MWKTitle*)title {
    MWKArticle* article = [self.dataStore articleWithTitle:title];

    WMFArticleContainerViewController* vc =
        [[WMFArticleContainerViewController alloc] initWithDataStore:self.dataStore
                                                          savedPages:self.savedPageList];
    vc.article = article;

    WMFPreviewController* previewController = [[WMFPreviewController alloc] initWithPreviewViewController:vc presentingViewController:self tabBarController:self.navigationController.tabBarController];
    previewController.delegate = self;
    [previewController presentPreviewAnimated:YES];

    self.previewController = previewController;
}

#pragma mark - Analytics

- (NSString*)analyticsName {
    return [self.articleViewController analyticsName];
}

#pragma mark - WMFPreviewControllerDelegate

- (void)previewController:(WMFPreviewController*)previewController didPresentViewController:(UIViewController*)viewController {
    self.previewController = nil;
    [self.navigationController pushViewController:viewController animated:NO];
}

- (void)previewController:(WMFPreviewController*)previewController didDismissViewController:(UIViewController*)viewController {
    self.previewController = nil;
}

#pragma mark - Saved Pages

- (void)observeSavedPages {
    [self.KVOControllerNonRetaining observe:self.savedPageList
                                    keyPath:WMF_SAFE_KEYPATH(self.savedPageList, entries)
                                    options:0
                                      block:^(WMFArticleContainerViewController* observer, id object, NSDictionary* change) {
        [observer updateSavedButtonState];
    }];
}

- (void)unobserveSavedPages {
    [self.KVOControllerNonRetaining unobserve:self.savedPageList keyPath:WMF_SAFE_KEYPATH(self.savedPageList, entries)];
}

- (IBAction)toggleSave:(id)sender {
    if (![self.article isCached]) {
        [self.articleViewController fetchArticle];
    }

    [self unobserveSavedPages];
    [self.savedPageList toggleSavedPageForTitle:self.article.title];
    [self.savedPageList save];
    [self observeSavedPages];
    [self updateSavedButtonState];
}

- (void)updateSavedButtonState {
    ((UIButton*)self.saveButton.customView).selected = [self isSaved];
}

- (BOOL)isSaved {
    return [self.savedPageList isSaved:self.article.title];
}

- (void)dealloc {
    [self unobserveSavedPages];
}

@end

NS_ASSUME_NONNULL_END
