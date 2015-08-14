#import "WMFArticleContainerViewController.h"
#import "WMFArticleContainerViewController_Transitioning.h"

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
<WMFWebViewControllerDelegate, WMFArticleViewControllerDelegate>
@property (nonatomic, strong) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) MWKDataStore* dataStore;

@property (nonatomic, strong, readwrite) WMFArticleViewController* articleViewController;
@property (nonatomic, strong, readwrite) WebViewController* webViewController;
@property (nonatomic, weak) UIViewController<WMFArticleContentController>* currentArticleController;

@property (nonatomic, weak) UIBarButtonItem* toggleCurrentControllerButton;

@end

@implementation WMFArticleContainerViewController
@synthesize popupTransition = _popupTransition;

+ (instancetype)articleContainerViewControllerWithDataStore:(MWKDataStore*)dataStore
                                                 savedPages:(MWKSavedPageList*)savedPages {
    return [[self alloc] initWithDataStore:dataStore savedPages:savedPages];
}

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore savedPages:(MWKSavedPageList*)savedPages {
    self = [super init];
    if (self) {
        self.savedPageList            = savedPages;
        self.dataStore                = dataStore;
        self.currentArticleController = self.articleViewController;
        [self configureNavigationItem];
    }
    return self;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.article.title];
}

#pragma mark - Accessors

- (WMFArticlePopupTransition*)popupTransition {
    if (!_popupTransition) {
        _popupTransition = [[WMFArticlePopupTransition alloc] initWithPresentingViewController:self];
    }
    return _popupTransition;
}

- (NSString*)toggleButtonTitle {
    // TODO: come up with better (localized) names
    if (self.currentArticleController == self.articleViewController) {
        return @"Web";
    } else {
        return @"Native";
    }
}

- (MWKArticle* __nullable)article {
    return self.currentArticleController.article;
}

- (void)setArticle:(MWKArticle* __nullable)article {
    if (WMF_EQUAL(self.article, isEqualToArticle:, article)) {
        return;
    }

    self.articleViewController.article = article;
    self.webViewController.article     = article;
    self.title                         = article.title.text;
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

- (void)setCurrentArticleController:(UIViewController<WMFArticleContentController>*)currentArticleController {
    [self setCurrentArticleController:currentArticleController animated:NO];
}

- (BOOL)isChildContentControllerViewInstalled:(UIViewController*)viewController {
    return [viewController isViewLoaded] && viewController.view.superview == self.view;
}

- (void)setCurrentArticleController:(UIViewController<WMFArticleContentController>*)currentArticleController
                           animated:(BOOL)animated {
    if (self.currentArticleController == currentArticleController
        && [self isChildContentControllerViewInstalled:currentArticleController]) {
        DDLogVerbose(@"Ignoring redundant set of currentArticleController");
        return;
    }

    if (currentArticleController.parentViewController != self) {
        [self addChildViewController:currentArticleController];
    }

    // prevent premature view loading
    if ([self isViewLoaded]) {
        [self transitionFromPreviousArticleController:self.currentArticleController
                                  toArticleController:currentArticleController
                                             animated:animated];
    } else {
        [self primitiveSetCurrentArticleController:currentArticleController];
    }
}

- (void)transitionFromPreviousArticleController:(UIViewController<WMFArticleContentController>* __nullable)previousController
                            toArticleController:(UIViewController<WMFArticleContentController>* __nullable)currentArticleController
                                       animated:(BOOL)animated {
    [self transitionFromViewController:previousController
                      toViewController:currentArticleController
                              duration:animated ? [CATransaction animationDuration] : 0.0
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
        [self setupCurrentArticleController:currentArticleController];
    }
                            completion:^(BOOL finished) {
        NSParameterAssert(finished);
        [self primitiveSetCurrentArticleController:currentArticleController];
        // !!!: this has to be done in completion, otherwise the animation will report as not having finished
        [self updateNavigationBarStateForViewController:currentArticleController];
    }];
}

- (void)setupCurrentArticleController:(UIViewController<WMFArticleContentController>*)currentArticleController {
    [currentArticleController.view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.leading.trailing.top.and.bottom.equalTo(self.view);
    }];
    [self updateNavigationBarStateForViewController:currentArticleController];
}

- (void)updateNavigationBarStateForViewController:(UIViewController*)viewController {
    [self.navigationController setNavigationBarHidden:viewController != self.webViewController
                                             animated:NO];
    // !!!: custom transitions don't handle back button presses very nicely, so disable for now
    self.navigationItem.hidesBackButton = viewController == self.webViewController;
}

- (void)toggleCurrentArticleController {
    if (self.currentArticleController == self.articleViewController) {
        [self setCurrentArticleController:self.webViewController animated:YES];
    } else {
        [self setCurrentArticleController:self.articleViewController animated:YES];
    }
}

- (void)primitiveSetCurrentArticleController:(UIViewController<WMFArticleContentController>*)currentArticleController {
    NSAssert(_currentArticleController != currentArticleController,
             @"Caller should have already performed equality checks and acted accordingly.");
    _currentArticleController = currentArticleController;
    [_currentArticleController didMoveToParentViewController:self];
    self.toggleCurrentControllerButton.title = [self toggleButtonTitle];
}

#pragma mark - WebView Transition

- (void)showWebViewAtFragment:(NSString*)fragment {
    [self.webViewController scrollToFragment:fragment];
    [self setCurrentArticleController:self.webViewController animated:YES];
}

#pragma mark - ViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateNavigationBarStateForViewController:self.currentArticleController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // !!!: currentArticleController's view must be added manually. otherwise this is done by VC transition APIs
    [self.view addSubview:self.currentArticleController.view];
    [self setupCurrentArticleController:self.currentArticleController];
}

- (void)configureNavigationItem {
    UIBarButtonItem* toggleCurrentControllerButton =
        [[UIBarButtonItem alloc] initWithTitle:[self toggleButtonTitle]
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(toggleCurrentArticleController)];
    self.toggleCurrentControllerButton = toggleCurrentControllerButton;

    self.navigationItem.rightBarButtonItems = @[
        self.toggleCurrentControllerButton
    ];
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
    [self showWebViewAtFragment:fragment];
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
    [self showWebViewAtFragment:fragment];
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

- (void)dismissWebViewController:(WebViewController*)controller {
    [self setCurrentArticleController:self.articleViewController];
}

#pragma mark - Popup

- (void)presentPopupForTitle:(MWKTitle*)title {
    MWKArticle* article                   = [self.dataStore articleWithTitle:title];
    WMFArticleContainerViewController* vc =
        [[WMFArticleContainerViewController alloc] initWithDataStore:self.dataStore
                                                          savedPages:self.savedPageList];
    [vc setMode:WMFArticleControllerModePopup animated:NO];

    vc.article = article;
    [self.navigationController pushViewController:vc animated:YES];
}

@end

NS_ASSUME_NONNULL_END
