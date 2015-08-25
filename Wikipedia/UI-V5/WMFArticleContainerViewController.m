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

// View
#import "WMFArticlePopupTransition.h"

// Other
#import "SessionSingleton.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleContainerViewController ()
<WMFWebViewControllerDelegate, WMFArticleViewControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) MWKDataStore* dataStore;

@property (nonatomic, strong) UINavigationController* contentNavigationController;
@property (nonatomic, strong, readwrite) WMFArticleViewController* articleViewController;
@property (nonatomic, strong, readwrite) WebViewController* webViewController;

@property (nonatomic, weak, readonly) UIViewController<WMFArticleContentController>* currentArticleController;

@end

@implementation WMFArticleContainerViewController
@synthesize popupTransition = _popupTransition;
@synthesize article         = _article;

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

- (WMFArticlePopupTransition*)popupTransition {
    if (!_popupTransition) {
        _popupTransition = [[WMFArticlePopupTransition alloc] initWithPresentingViewController:self];
    }
    return _popupTransition;
}

- (WMFArticleViewController*)articleViewController {
    if (!_articleViewController) {
        _articleViewController = [WMFArticleViewController articleViewControllerWithDataStore:self.dataStore
                                                                                   savedPages:self.savedPageList];
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
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateInsetsForArticleViewController];
}

- (void)updateInsetsForArticleViewController {
    CGFloat navHeight = [self.navigationController.navigationBar frame].size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
    self.articleViewController.tableView.contentInset = UIEdgeInsetsMake(navHeight, 0.0, 0.0, 0.0);
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
    MWKArticle* article                   = [self.dataStore articleWithTitle:title];
    WMFArticleContainerViewController* vc =
        [[WMFArticleContainerViewController alloc] initWithDataStore:self.dataStore
                                                          savedPages:self.savedPageList];

    vc.article = article;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Analytics

- (NSString*)analyticsName {
    return [self.articleViewController analyticsName];
}

@end

NS_ASSUME_NONNULL_END
